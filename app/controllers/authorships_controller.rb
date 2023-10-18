# frozen_string_literal: true

class AuthorshipsController < ApplicationController
  before_action :check_authorization
  before_action :ensure_json_request
  before_action :ensure_request_body_exists
  skip_forgery_protection # this controller only has API calls from profiles

  # This POST creates or updates an "authorship" record, i.e. an association between an existing
  # publication and an existing author.  If updating, all information will be replaced in the existing
  # contribution.  For partial updates, use "PATCH" below.
  # You POST JSON like this:
  #  {"cap_profile_id":"2","featured":false,"status":"approved","visibility":"PUBLIC","sul_pub_id":"1"}
  #  Authors can be identified using "cap_profile_id" or "sul_author_id" (primary key on our author table)
  #  Publications can be identified using "sul_pub_id" (primary key on our publications table), "pmid", "sw_id", or "wos_uid"
  #  At least one author identifier and one publication identifier are required
  # POST /authorship.json
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def create
    logger.info('POST Contribution JSON: ')
    logger.info(request_body)
    params = hashed_request
    if params[:cap_profile_id].blank? && params[:sul_author_id].blank?
      log_and_error! "The request is missing 'sul_author_id' and 'cap_profile_id'.", :bad_request
      return
    end

    author = params[:cap_profile_id] ? get_cap_author!(params[:cap_profile_id]) : get_sul_author!(params[:sul_author_id])
    return unless author # can't find the author
    return unless author_id_consistent?(author, params[:cap_profile_id]) # ids aren't consistent

    ids = params.slice(:sul_pub_id, :pmid, :sw_id, :wos_uid).to_h.symbolize_keys
    ids.compact_blank!
    unless ids.any?
      render json: { error: 'You have not supplied any publication identifier: sul_pub_id || pmid || sw_id || wos_uid' },
             status: :bad_request, format: :json
      return
    end

    # Now find an existing sul publication or, if it doesn't exist, it
    # may be fetched from PubMed (pmid), WebOfScience (wos_uid) or ScienceWire (sw_id).
    pub = get_local_publication!(ids[:sul_pub_id]) if ids[:sul_pub_id]
    pub ||= get_publication_via_pubmed!(ids[:pmid]) if ids[:pmid]
    pub ||= get_publication_via_sciencewire!(ids[:sw_id]) if ids[:sw_id]
    pub ||= get_publication_via_wos!(author, ids[:wos_uid]) if ids[:wos_uid]

    return unless pub # couldn't find the publication

    # We've now got the author and pub, validate the authorship and create or
    # update the contribution.  (When a request only requires an update, it
    # should use the PATCH method below.)

    pub_hash = create_or_update_and_return_pub_hash(pub, author, contrib_attr)
    return unless pub_hash

    render json: pub_hash.to_json, format: :json, status: :created
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  # The PATCH request option allows partial (or full) attribute updates on an
  # existing contribution (association between a publication and an author).
  # It will not create any new authors, publication or contributions. You PATCH JSON with the data.
  # It requires a 'sul_pub_id' (primary key on our publicaton table) to identify an *existing*
  # publication (it does not accept a 'pmid' or 'sw_id').  It accepts
  # 'sul_author_id' (primay key on our author table) or 'cap_profile_id' to identify
  #  an *existing* author.  If it can find an *existing* contribution for the given author and
  # publication, it will update any of the contribution attributes: featured,
  # status, or visibility.  Any or all of these can be included in the JSON
  # payload.  Any attributes that are not given should not be changed.
  # It thus allows partial updating for an existing contribution record
  # PATCH /authorship.json
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def update
    logger.info('PATCH Contribution JSON: ')
    logger.info(request_body)

    params = hashed_request
    if params[:cap_profile_id].blank? && params[:sul_author_id].blank?
      log_and_error! "The request is missing 'sul_author_id' and 'cap_profile_id'.", :bad_request
      return
    end
    author = params[:cap_profile_id] ? get_cap_author!(params[:cap_profile_id]) : get_sul_author!(params[:sul_author_id])
    return unless author # can't find the author
    return unless author_id_consistent?(author, params[:cap_profile_id]) # ids aren't consistent

    if params[:sul_pub_id].blank?
      render json: { error: 'You have not supplied the publication identifier sul_pub_id' }, status: :bad_request,
             format: :json
      return
    end

    # Find an existing contribution by author/publication
    contributions = Contribution.where(
      author_id: author.id,
      publication_id: params[:sul_pub_id]
    )
    if contributions.empty?
      log_and_error!("SULCAP has no contributions by the author:#{author.id} for the publication:#{params[:sul_pub_id]}")
      return
    elsif contributions.length > 1
      # Hitting this block of code should be a cause for concern, bad internal data
      log_and_error!(
        "SULCAP has multiple contributions by the author:#{author.id} for the publication:#{params[:sul_pub_id]}", :internal_server_error
      )
      return
    end
    pub = contributions.first.publication

    unless pub
      # Also a cause for concern, bad internal data
      log_and_error!('No publication found', :internal_server_error)
      return
    end

    # We've now got the contribution, gather the new attributes.  In a PATCH
    # request, it's OK if some of them are missing; validate only the
    # fields provided.  When check for 'featured', use .nil? because it
    # is allowed to have a `false` value.
    unless !contrib_attr[:featured].nil? || contrib_attr[:status].present? || contrib_attr[:visibility].present?
      render json: { error: "At least one authorship attribute is required: 'featured', 'status', 'visibility'." },
             status: :not_acceptable, format: :json
      return
    end

    pub_hash = create_or_update_and_return_pub_hash(pub, author, contrib_attr)
    return unless pub_hash

    render json: pub_hash.to_json, format: :json, status: :accepted
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  private

  # Extract a hash of optional contribution parameters from the request.
  # When this method is called for a PATCH request, it's important that it does not set any defaults.
  # @return [Hash<Symbol => [String, Boolean]>] May contain any of :features, :status and :visibility
  def contrib_attr
    contrib_attr = {}
    %i[featured status visibility].each do |field|
      # check params[field].nil? not .blank? because featured can be `false`.
      contrib_attr[field] = params[field].to_s.downcase unless params[field].nil?
    end
    contrib_attr.with_indifferent_access
  end

  # A publication manages a contribution update, so that it can update
  # the data in the pub.pub_hash field. This is the most painful data
  # modeling aspect of this application. It maintains a Hash in a
  # Publication.pub_hash field, breaking the elegant design of a RDBMS.
  # @return [Hash] the entire pub_hash, not just the contribution
  # @note contribution should be in the pub_hash[:authorship] array
  def create_or_update_and_return_pub_hash(pub, author, authorship)
    contrib = pub.contributions.find_or_initialize_by(author_id: author.id)
    contrib.assign_attributes(authorship.merge(cap_profile_id: author.cap_profile_id, author_id: author.id))
    unless contrib.valid?
      render json: { error: 'You have not supplied a valid authorship record.' }, status: :not_acceptable, format: :json
      return false
    end
    pub.pubhash_needs_update! if contrib.persisted? && contrib.changed?
    begin
      contrib.save!
      pub.save! # sync the contribution into the pub.pub_hash[:authorship] array
    rescue StandardError => e
      log_and_error!("Could not save contribution #{contrib.id} or publication #{pub.id}\n#{e.message}",
                     :internal_server_error)
      return false
    end
    pub.pub_hash
  end

  def get_cap_author!(cap_profile_id)
    author = Author.find_by(cap_profile_id:) || Author.fetch_from_cap_and_create(cap_profile_id)
    unless author
      log_and_error!("SULCAP has no record for cap_profile_id: #{cap_profile_id}")
      false
    end
    author
  rescue StandardError => e
    log_and_error!("SULCAP cannot retrieve cap_profile_id: #{cap_profile_id}\n#{e.message}")
    false
  end

  def get_sul_author!(sul_author_id)
    Author.find(sul_author_id)
  rescue ActiveRecord::RecordNotFound
    log_and_error!("SULCAP has no record for sul_author_id: #{sul_author_id}")
    false
  end

  # Double check that the retrieved author matches the cap_profile_id sent
  def author_id_consistent?(author, cap_profile_id)
    return true if cap_profile_id.blank? || author.cap_profile_id == cap_profile_id.to_i

    # Author found by 'sul_author_id' has a different 'cap_profile_id' assigned, barf!
    msg = "SULCAP has an author record with a different cap_profile_id\n"
    msg += "Found     cap_profile_id: #{author.cap_profile_id} in sul_author_id: #{author.id}\n"
    msg += "Requested cap_profile_id: #{cap_profile_id}"
    log_and_error!(msg, :internal_server_error)
    false
  end

  # Find an existing SUL publication or, if it doesn't exist, it may be fetched based on ID provided
  # @param [String] sul_pub_id internal ID
  # @return [Publication]
  def get_local_publication!(sul_pub_id)
    Publication.find(sul_pub_id)
  rescue ActiveRecord::RecordNotFound
    log_and_error!("The SUL:#{sul_pub_id} publication does not exist.")
    false
  end

  # @param [String] pmid PubMed ID
  # @return [Publication]
  def get_publication_via_pubmed!(pmid)
    pub = Publication.find_or_create_by_pmid(pmid.delete_prefix('MEDLINE:'))
    unless pub
      log_and_error!("The PMID:#{pmid} was not found either locally or at PubMed.")
      false
    end
    pub
  end

  # @param [String] sw_id ScienceWire ID
  # @return [Publication]
  def get_publication_via_sciencewire!(sw_id)
    pub = Publication.find_by(sciencewire_id: sw_id) || SciencewireSourceRecord.get_pub_by_sciencewire_id(sw_id)
    unless pub
      log_and_error!("The publication with SWID:#{sw_id} was not found locally.")
      false
    end
    pub
  end

  # @param [Author] author, note this variation from other methods, because harvester requires author
  # @param [String] wos_uid WebOfScience ID
  # @return [Publication]
  def get_publication_via_wos!(author, wos_uid)
    WebOfScience.harvester.author_uid(author, wos_uid)
    wossr = WebOfScienceSourceRecord.find_by(uid: wos_uid)
    unless wossr
      log_and_error!("A WebOfScienceSourceRecord was not found for WOS_UID:#{wos_uid}.")
      return false
    end

    # we find the publication by looking for any matching publication for this WOS source record (could be MEDLINE or WOS ID, use all valid identifiers)
    pub = wossr.record.matching_publication
    return pub if pub

    log_and_error!("A matching publication record for WOS_UID:#{wos_uid} was not found in the publication table.")
    false
  end
end
