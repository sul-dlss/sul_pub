# frozen_string_literal: true

class PublicationsController < ApplicationController
  before_action :check_authorization
  before_action :ensure_json_request, except: [:index]
  before_action :ensure_request_body_exists, only: %i[create update]
  skip_forgery_protection # this controller only has API calls from profiles

  # Retreive publications for a specific profile ID, optionally in a given time period
  # GET /publications.json                                        # all publications
  # GET /publications.json?capProfileId=1                         # publications on this profile
  # GET /publications.json?capProfileId=1&changedSince=2018-01-01 # publications on this profile since that date
  # GET /publications.json?capActive=true                         # all publications for users active in cap
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def index
    msg = 'Getting publications'
    msg += " for profile #{params[:capProfileId]}" if params[:capProfileId]
    msg += " where capActive = #{params[:capActive]}" if params[:capActive]
    msg += " where updated_at > #{params[:changedSince]}" if params[:changedSince]
    logger.info msg

    default_per = 1000 # default and max number of records per page
    matching_records = []
    capProfileId = params[:capProfileId]
    capActive = params[:capActive]
    page = params.fetch(:page, 1).to_i
    per = [params.fetch(:per, default_per).to_i, default_per].min
    last_changed = Time.zone.parse(params[:changedSince]) if params[:changedSince]

    if capProfileId.blank?
      matching_records = Publication.select(:id, :pub_hash).page(page).per(per)
      matching_records = matching_records.updated_after(last_changed) if last_changed.present?
      matching_records = matching_records.with_active_author if capActive.present? && (capActive || capActive.casecmp('true').zero?)
      matching_records = matching_records.order('publications.id')
    else
      author = Author.find_by(cap_profile_id: capProfileId)
      if author.nil?
        render json: { error: "No such author with capProfileId #{capProfileId}" }, status: :not_found, format: 'json'
        return
      end
      matching_records = author.publications.order('publications.id').page(page).per(per).select(:pub_hash) unless params[:format] =~ /csv/i
    end
    logger.debug("Found #{matching_records.length} records")

    respond_to do |format|
      format.json do
        render json: wrap_as_bibjson_collection(msg, matching_records, page, per)
      end
      format.csv do
        if author
          send_data(generate_csv_report(author), filename: 'author_report.csv')
        else # this format doesn't work except for a single author
          render plain: 'CSV not available for all publications; must select single author', status: :bad_request
        end
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  # return a specific publication
  # GET /publications/399607
  def show
    pub = Publication.find_by(id: params[:id])
    if pub.blank?
      head :not_found
      return
    elsif pub.deleted?
      head :gone
      return
    end
    render json: pub.pub_hash
  end

  # create a new manual publication by posting BibJSON (in body)
  # POST /publications
  def create
    logger.info('POST Create:')
    logger.info(request_body)
    pub_hash = hashed_request
    fingerprint = Digest::SHA2.hexdigest(request_body)
    existing_record = UserSubmittedSourceRecord.find_by(source_fingerprint: fingerprint)
    if existing_record
      logger.info("Found existing record for #{fingerprint}: #{existing_record.inspect}; redirecting.")
      redirect_to publication_path(existing_record.publication_id), status: :see_other
    else
      unless validate_or_create_authors(pub_hash[:authorship])
        render json: { error: 'You have not supplied a valid authorship record.' }, status: :not_acceptable,
               format: 'json'
        return
      end
      pub = Publication.build_new_manual_publication(pub_hash, request_body)
      pub.save!
      pub.reload
      logger.debug("Created new publication #{pub.inspect}")
      render json: pub.pub_hash, status: :created
    end
  end

  # update a publication by putting BibJSON (in body)
  # PUT /publications/1234
  # rubocop:disable Metrics/AbcSize
  def update
    logger.info('PUT Update:')
    logger.info(request_body)
    new_pub = hashed_request
    old_pub = Publication.find_by(id: params[:id])
    if old_pub.blank?
      head :not_found
      return
    elsif old_pub.deleted?
      head :gone
      return
    end
    if old_pub.harvested_pub? # only manually entered (i.e. non-harvested) publications may be updated with this method
      render json: {
               error: "This record SulPubID #{old_pub.id} may not be modified.  If you had originally entered details for the record, " \
                      'it has been superceded by a central record.'
             },
             status: :forbidden, format: 'json'
      return
    elsif !validate_or_create_authors(new_pub[:authorship])
      render json: { error: 'You have not supplied a valid authorship record.' }, status: :not_acceptable,
             format: 'json'
      return
    end
    logger.info("Update manual publication #{old_pub.inspect} with BibJSON:")
    logger.info(request_body)
    old_pub.update_manual_pub_from_pub_hash(new_pub, request_body)
    old_pub.save!
    old_pub.reload
    logger.debug("resulting pub hash: #{old_pub.pub_hash}")
    render json: old_pub.pub_hash, status: :accepted
  end
  # rubocop:enable Metrics/AbcSize

  # mark a publication as deleted
  # DELETE /publications/1234
  def destroy
    pub = Publication.find_by(id: params[:id])
    if pub.blank?
      head :not_found
      return
    elsif pub.deleted?
      head :gone
      return
    end
    pub.delete!
    render json: pub.id
  end

  # Look up publications by title, doi or pmid -- used by Profiles for manual publication searches
  # GET /publications/sourcelookup.json?title=Noise+Power+Spectra    # search by title
  # GET /publications/sourcelookup.json?doi=10.1109/T-PAS.1977.32416 # search by DOI
  # GET /publications/sourcelookup.json?pmid=12345                   # search by PMID
  # rubocop:disable Metrics/AbcSize
  def sourcelookup
    all_matching_records = []
    if params[:doi]
      msg = "Sourcelookup of doi #{params[:doi]}"
      logger.info(msg)
      all_matching_records += DoiSearch.search(params[:doi].strip)
    elsif params[:pmid]
      msg = "Sourcelookup of pmid #{params[:pmid]}"
      logger.info(msg)
      all_matching_records += Pubmed::Fetcher.search_all_sources_by_pmid(params[:pmid].strip)
    elsif params[:title].presence
      title = params[:title].delete('"')
      msg = "Sourcelookup of title '#{title}'"
      logger.info(msg)
      if Settings.WOS.enabled
        query = "TI=\"#{title}\""
        query += " AND PY=#{params[:year]}" if params[:year]
        query_params = WebOfScience::UserQueryRestRetriever::Query.new(database: 'WOS')
        wos_matches = WebOfScience::Queries.new.user_query(query, query_params:).next_batch.to_a # limit: only 1 batch and only to WOS database
        all_matching_records += wos_matches
        logger.debug(" -- WOS (#{wos_matches.length})")
      end
      # lastly, always check for manual
      results = Publication.joins(:user_submitted_source_records)
                           .where(UserSubmittedSourceRecord.arel_table[:title].matches("%#{params[:title]}%"))
      results = results.where(year: params[:year]) if params[:year]
      logger.debug(" -- manual source (#{results.length})")
      all_matching_records += results
    else # no search terms provided
      head :bad_request
      return
    end
    # When params[:maxrows] is nil/zero, -1 returns everything
    matching_records = all_matching_records[0..params[:maxrows].to_i - 1] # rubocop:disable Lint/AmbiguousRange
    render json: wrap_as_bibjson_collection(msg, matching_records)
  end
  # rubocop:enable Metrics/AbcSize

  private

  # @return [Hash]
  def wrap_as_bibjson_collection(description, records, page = 1, per_page = 'all')
    metadata = {
      _created: Time.zone.now.iso8601,
      description:,
      format: 'BibJSON',
      license: 'some licence',
      page:,
      per_page:,
      query: request.env['ORIGINAL_FULLPATH'].to_s,
      records: records.count.to_s
    }
    {
      metadata:,
      records: records.map { |x| (x.pub_hash if x.respond_to? :pub_hash) || x }
    }
  end

  # @param [Author] author
  # @return [String] contains csv report of an author's publications
  # rubocop:disable Metrics/AbcSize
  def generate_csv_report(author)
    CSV.generate do |csv|
      csv << %w[sul_pub_id sciencewire_id pubmed_id doi wos_id title journal year pages issn status_for_this_author
                created_at updated_at contributor_cap_profile_ids]
      author.publications.find_each do |pub|
        journ = pub.pub_hash[:journal] ? pub.pub_hash[:journal][:name] : ''
        contrib_prof_ids = pub.authors.pluck(:cap_profile_id).join(';')
        wos_id = pub.publication_identifiers.where(identifier_type: 'WoSItemID').pick(:identifier_value)
        doi = pub.publication_identifiers.where(identifier_type: 'doi').pick(:identifier_value)
        status = pub.contributions.where(author_id: author.id).pick(:status)
        created_at = pub.created_at.utc.strftime('%m/%d/%Y')
        updated_at = pub.updated_at.utc.strftime('%m/%d/%Y')

        csv << [pub.id, pub.sciencewire_id, pub.pmid, doi, wos_id, pub.title, journ, pub.year, pub.pages, pub.issn,
                status, created_at, updated_at, contrib_prof_ids]
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  # Check for existing authors or create new authors with a CAP profile ID.
  # At least one of the authors in the authorship array must exist or have
  # a CAP profile that is used to create a new SULCAP author.
  # @param authorship_list [Array<Hash>]
  # @return [Boolean] true if any authors exist or are created.
  def validate_or_create_authors(authorship_list) # rubocop:disable Naming/PredicateMethod
    return false if authorship_list.blank?

    groups = authorship_list.group_by { |auth| Contribution.authorship_valid?(auth) }
    unknowns = groups[false] || []
    cap_ids = unknowns.pluck(:cap_profile_id).compact
    cap_ids.map { |id| Author.fetch_from_cap_and_create(id) }.any? ||
      groups[true].any?
  end
end
