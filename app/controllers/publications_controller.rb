require 'csv'

class PublicationsController < ApplicationController
  before_action :check_authorization

  def index
    msg = "Getting publications"
    msg += " for profile #{params[:capProfileId]}" if params[:capProfileId]
    msg += " where capActive = #{params[:capActive]}" if params[:capActive]
    msg += " where updated_at > #{params[:changedSince]}" if params[:changedSince]
    logger.info msg

    matching_records = []
    capProfileId = params[:capProfileId]
    capActive = params[:capActive]
    page = params.fetch(:page, 1).to_i
    per = params.fetch(:per, 1000).to_i
    last_changed = Time.zone.parse(params.fetch(:changedSince, '1000-01-01')).to_s

    benchmark 'Querying for publications' do
      if capProfileId.blank?
        description = "Records that have changed since #{last_changed}"
        query = Publication.updated_after(last_changed).page(page).per(per)
        query = query.with_active_author if !capActive.blank? && capActive.casecmp('true').zero?
        matching_records = query.select(:pub_hash)
      else
        author = Author.find_by(cap_profile_id: capProfileId)
        if author.nil?
          render status: 404, body: "No such author with capProfileId #{capProfileId}"
          return
        end
        unless params[:format] =~ /csv/i
          matching_records = author.publications.order('publications.id').page(page).per(per).select(:pub_hash)
        end
      end
      logger.debug("Found #{matching_records.length} records")

      respond_to do |format|
        format.json do
          render json: wrap_as_bibjson_collection(description, matching_records, page, per)
        end
        format.csv do
          render csv: generate_csv_report(author), filename: 'author_report', chunked: true
        end
      end
    end
  end

  # Look up existing records by title, and optionally by author, year and source
  def sourcelookup
    all_matching_records = []
    msg = 'Sourcelookup of '
    if params[:doi]
      msg << "doi #{params[:doi]}"
      logger.info(msg)
      all_matching_records += DoiSearch.search(params[:doi])
    elsif params[:pmid]
      msg << "pmid #{params[:pmid]}"
      logger.info(msg)
      all_matching_records += PubmedHarvester.search_all_sources_by_pmid(params[:pmid])
    else
      raise ActionController::ParameterMissing, :title unless params[:title].presence
      msg << "title '#{params[:title]}'"
      logger.info(msg)
      if Settings.WOS.enabled
        query = "TI=#{params[:title]}"
        query += " AND PY=#{params[:year]}" if params[:year]
        wos_matches = WebOfScience.queries.user_query(query).to_a # TODO: limit
        all_matching_records += wos_matches
        logger.debug(" -- WOS (#{wos_matches.length})")
      end
      if Settings.SCIENCEWIRE.enabled
        sw_matches = ScienceWireClient.new.query_sciencewire_for_publication(nil, nil, nil, params[:title], params[:year], params.fetch(:max_rows, 20).to_i)
        all_matching_records += sw_matches
        logger.debug(" -- sciencewire (#{sw_matches.length})")
      end
      # lastly, always check for manual
      results = Publication.joins(:user_submitted_source_records)
                           .where(UserSubmittedSourceRecord.arel_table[:title].matches("%#{params[:title]}%"))
      results = results.where(year: params[:year]) if params[:year]
      logger.debug(" -- manual source (#{results.length})")
      all_matching_records += results
    end
    # When params[:maxrows] is nil/zero, -1 returns everything
    matching_records = all_matching_records[0..params[:maxrows].to_i - 1]
    respond_to do |format|
      format.json do
        render json: wrap_as_bibjson_collection(msg, matching_records)
      end
    end
  end

  private

    # @return [Hash]
    def wrap_as_bibjson_collection(description, records, page = 1, per_page = 'all')
      metadata = {
        _created: Time.zone.now.iso8601,
        description: description,
        format: 'BibJSON',
        license: 'some licence',
        page: page,
        per_page: per_page,
        query: env['ORIGINAL_FULLPATH'].to_s,
        records:  records.count.to_s
      }
      {
        metadata: metadata,
        records: records.map { |x| (x.pub_hash if x.respond_to? :pub_hash) || x }
      }
    end

    # @param [Author] author
    # @return [String] contains csv report of an author's publications
    def generate_csv_report(author)
      CSV.generate do |csv|
        csv << %w(sul_pub_id sciencewire_id pubmed_id doi wos_id title journal year pages issn status_for_this_author created_at updated_at contributor_cap_profile_ids)
        author.publications.find_each do |pub|
          journ = pub.pub_hash[:journal] ? pub.pub_hash[:journal][:name] : ''
          contrib_prof_ids = pub.authors.pluck(:cap_profile_id).join(';')
          wos_id = pub.publication_identifiers.where(identifier_type: 'WoSItemID').pluck(:identifier_value).first
          doi = pub.publication_identifiers.where(identifier_type: 'doi').pluck(:identifier_value).first
          status = pub.contributions.where(author_id: author.id).pluck(:status).first
          created_at = pub.created_at.utc.strftime('%m/%d/%Y')
          updated_at = pub.updated_at.utc.strftime('%m/%d/%Y')

          csv << [pub.id, pub.sciencewire_id, pub.pmid, doi, wos_id, pub.title, journ, pub.year, pub.pages, pub.issn, status, created_at, updated_at, contrib_prof_ids]
        end
      end
    end
end
