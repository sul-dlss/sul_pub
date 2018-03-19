module SulBib
  class AuthorshipAPI < Grape::API
    version 'v1', using: :header, vendor: 'sul', format: :json
    format :json

    helpers do
      # Extract a hash of optional contribution parameters from the request.
      # When this method is called for a PATCH request, it's important that it does not set any defaults.
      # @return [Hash<Symbol => [String, Boolean]>] May contain any of :features, :status and :visibility
      def contrib_attr
        contrib_attr = {}
        [:featured, :status, :visibility].each do |field|
          # check params[field].nil? not .blank? because featured can be `false`.
          contrib_attr[field] = params[field] unless params[field].nil?
        end
        contrib_attr
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
        # error!('You have not supplied a valid authorship record.', 406)
        pub.pubhash_needs_update! if contrib.persisted? && contrib.changed?
        begin
          contrib.save!
          pub.save! # sync the contribution into the pub.pub_hash[:authorship] array
        rescue ActiveRecord::ActiveRecordError => e
          error!(e.inspect, 500)
        end
        pub.pub_hash
      end

      # Find an existing Author by 'cap_profile_id' or 'sul_author_id'.  This
      # helper can retrieve a CAP profile if an author does not exist yet.
      def get_author!(cap_profile_id, sul_author_id)
        if cap_profile_id.blank? && sul_author_id.blank?
          log_and_error!("The request is missing 'sul_author_id' and 'cap_profile_id'.", 400)
        end
        author = cap_profile_id ? get_cap_author(cap_profile_id) : get_sul_author(sul_author_id)
        check_author_ids!(author, cap_profile_id)
        author
      end

      def get_cap_author(cap_profile_id)
        Author.find_by(cap_profile_id: cap_profile_id) ||
          Author.fetch_from_cap_and_create(cap_profile_id) ||
          log_and_error!("SULCAP has no record for cap_profile_id: #{cap_profile_id}")
      rescue => e
        log_and_error!("SULCAP cannot retrieve cap_profile_id: #{cap_profile_id}\n#{e.message}")
      end

      def get_sul_author(sul_author_id)
        Author.find(sul_author_id)
      rescue ActiveRecord::RecordNotFound
        log_and_error!("SULCAP has no record for sul_author_id: #{sul_author_id}")
      end

      # Double check they aren't identifying two different authors
      def check_author_ids!(author, cap_profile_id)
        return if cap_profile_id.blank? || author.cap_profile_id == cap_profile_id.to_i
        # Author found by 'sul_author_id' has a different 'cap_profile_id' assigned, barf!
        msg = "SULCAP has an author record with a different cap_profile_id\n"
        msg += "Found     cap_profile_id: #{author.cap_profile_id} in sul_author_id: #{author.id}\n"
        msg += "Requested cap_profile_id: #{cap_profile_id}"
        log_and_error!(msg, 500)
      end

      # Find an existing contribution by author/publication
      def get_contribution(author, sul_pub_id)
        contributions = Contribution.where(
          author_id: author.id,
          publication_id: sul_pub_id
        )
        if contributions.empty?
          log_and_error!("SULCAP has no contributions by the author:#{author.id} for the publication:#{sul_pub_id}")
        elsif contributions.length > 1
          # Hitting this block of code should be a cause for concern.
          log_and_error!("SULCAP has multiple contributions by the author:#{author.id} for the publication:#{sul_pub_id}", 500)
        end
        contributions.first
      end

      # Find an existing SUL publication or, if it doesn't exist, it may be fetched based on ID provided
      # @param [String] sul_pub_id internal ID
      # @return [Publication]
      def get_local_publication!(sul_pub_id)
        Publication.find(sul_pub_id)
      rescue ActiveRecord::RecordNotFound
        log_and_error!("The SUL:#{sul_pub_id} publication does not exist.")
      end

      # @param [String] pmid PubMed ID
      # @return [Publication]
      def get_publication_via_pubmed!(pmid)
        Publication.find_or_create_by_pmid(pmid) ||
          log_and_error!("The PMID:#{pmid} was not found either locally or at PubMed.")
      end

      # @param [String] sw_id ScienceWire ID
      # @return [Publication]
      def get_publication_via_sciencewire!(sw_id)
        Publication.find_by(sciencewire_id: sw_id) ||
          SciencewireSourceRecord.get_pub_by_sciencewire_id(sw_id) ||
          log_and_error!("The ScienceWire:#{sw_id} publication was not found either locally or at ScienceWire.")
      end

      # @param [Author] author, note this variation from other methods, because harvester requires author
      # @param [String] wos_uid WebOfScience ID
      # @return [Publication]
      def get_publication_via_wos!(author, wos_uid)
        WebOfScience.harvester.author_uid(author, wos_uid)
        Publication.find_by(wos_uid: wos_uid) ||
          log_and_error!("The #{wos_uid} publication was not found either locally or at WebOfScience.")
      end

      # @param [String] msg Message to log and send in response
      # @param [Integer] code HTTP status code
      def log_and_error!(msg, code = 404)
        logger.error msg
        error!(msg, code)
      end
    end

    # This POST can create new authors and publications or update an existing
    # contribution for existing author/publication records. The update operation
    # should be done in a PUT or PATCH request. However, the API never shares
    # the contribution.id value to precisely target it. Nevertheless, it should
    # be possible to target the contribution using the author.id and the
    # publication.id.  The API design, however, allows many options for POST
    # inputs, so it conflates creation with update in a POST.

    desc 'Allows creating a new authorship/contribution record, or updating an existing record'
    content_type :json, 'application/json'
    params do
      # The request can identify a publication with any one of these params:
      optional :sul_pub_id, type: String, desc: 'The JSON body can contain a SUL publication identifier: "sul_pub_id".'
      optional :pmid, type: String, desc: 'The JSON body can contain a PubMed identifier: "pmid".'
      optional :sw_id, type: String, desc: 'The JSON body can contain a ScienceWire identifier with "sw_id".'
      optional :wos_uid, type: String, desc: 'The JSON body can contain a WebOfScience identifier with "wos_uid".'

      # The request can identify an author by either of these params:
      optional :sul_author_id, type: String, desc: 'The JSON body can contain an author identifier: "sul_author_id".'
      optional :cap_profile_id, type: String, desc: 'The JSON body can contain an author identifier: "cap_profile_id".'

      # Require all of these contribution attributes, without defining defaults.
      # If they were optional, with defaults, an update request that only
      # provides say, status, could mistakenly assign new default values to all
      # the other attributes of an existing contribution.  Because this POST
      # conflates creation with update, these attributes must be explicit.
      requires :featured, type: Boolean, desc: 'The JSON body must indicate if the contribution is featured'
      requires :status, type: String, desc: 'The JSON body must indicate if the contribution is approved', coerce_with: ->(val) { val.downcase }
      requires :visibility, type: String, desc: 'The JSON body must indicate if the contribution is visible', coerce_with: ->(val) { val.downcase }
    end
    post do
      logger.info('POST Contribution JSON: ')
      logger.info(env['api.request.input'].to_s)

      # Find or create an author
      author = get_author!(
        params[:cap_profile_id],
        params[:sul_author_id]
      )

      ids = params.slice(:sul_pub_id, :pmid, :sw_id, :wos_uid).to_h.symbolize_keys
      ids.reject! { |_, v| v.blank? }
      unless ids.any?
        log_and_error!('There is no valid publication identifier: sul_pub_id || pmid || sw_id || wos_uid.', 400)
      end

      # Now find an existing sul publication or, if it doesn't exist, it
      # may be fetched from PubMed (pmid), WebOfScience (wos_uid) or ScienceWire (sw_id).
      pub = get_local_publication!(ids[:sul_pub_id]) if ids[:sul_pub_id]
      pub ||= get_publication_via_pubmed!(ids[:pmid]) if ids[:pmid]
      pub ||= get_publication_via_sciencewire!(ids[:sw_id]) if ids[:sw_id]
      pub ||= get_publication_via_wos!(author, ids[:wos_uid]) if ids[:wos_uid]

      # We've now got the author and pub, validate the authorship and create or
      # update the contribution.  (When a request only requires an update, it
      # should use the PATCH method below.)

      # Contribution.valid_fields? will confirm the authorship fields are
      # present and valid; the GrapeAPI checks the presence of required params.
      Contribution.valid_fields?(contrib_attr) ||
        error!('You have not supplied a valid authorship record.', 406)
      create_or_update_and_return_pub_hash(pub, author, contrib_attr)
    end # post end

    # TODO: create, enable, and test PUT API method.

    # PATCH is defined in https://tools.ietf.org/html/rfc5789
    #
    # The PATCH request option allows partial (or full) attribute updates on an
    # existing contribution.  It will not create any new author, publication or
    # contribution.  It requires a 'sul_pub_id' to identify an *existing*
    # publication (it does not accept a 'pmid' or 'sw_id').  It accepts
    # 'sul_author_id' or 'cap_profile_id' to identify an *existing* author.  If
    # it can find an *existing* contribution for the given author and
    # publication, it will update any of the contribution attributes: featured,
    # status, or visibility.  Any or all of these can be included in the JSON
    # payload.  Any attributes that are not given should not be changed.
    desc 'Allows partial updating for an existing contribution record'
    content_type :json, 'application/json'
    params do
      # The request must identify a publication with a sul_pub_id:
      requires :sul_pub_id, type: String, desc: 'The JSON body can contain a SUL publication identifier: "sul_pub_id".'

      # The request can identify an author by either of these params:
      optional :sul_author_id, type: String, desc: 'The JSON body can contain an author identifier: "sul_author_id".'
      optional :cap_profile_id, type: String, desc: 'The JSON body can contain an author identifier: "cap_profile_id".'

      # An update request can omit any of the contribution attributes, so long
      # as no defaults are specified here.
      optional :featured, type: Boolean, desc: 'The JSON body should indicate if the contribution is featured'
      optional :status, type: String, desc: 'The JSON body should indicate if the contribution is approved', coerce_with: ->(val) { val.downcase }
      optional :visibility, type: String, desc: 'The JSON body should indicate if the contribution is visible', coerce_with: ->(val) { val.downcase }
    end
    patch do
      logger.info('PATCH Contribution JSON: ')
      logger.info(env['api.request.input'].to_s)

      # Find an existing author
      author = get_author!(
        params[:cap_profile_id],
        params[:sul_author_id]
      )

      # Find an existing contribution by author/publication
      pub = get_contribution(author, params[:sul_pub_id]).publication

      # We've now got the contribution, gather the new attributes.  In a PATCH
      # request, it's OK if some of them are missing; validate only the
      # fields provided.  When check for 'featured', use .nil? because it
      # is allowed to have a `false` value.
      authorship_hash = contrib_attr.with_indifferent_access
      !authorship_hash[:featured].nil? ||
        authorship_hash[:status].present? ||
        authorship_hash[:visibility].present? ||
        error!("At least one authorship attribute is required: 'featured', 'status', 'visibility'.", 406)

      prototype = Contribution.new(authorship_hash.slice(:featured, :status, :visibility))
      prototype.validate # we KNOW it won't validate (w/o author and publication), but we check for the other fields
      errors = prototype.errors.messages.slice(:featured, :status, :visibility)
      if errors.present?
        msg = errors.map { |k, v| "The '#{k}' param is invalid: #{authorship_hash[k]} -- #{v}" }.join("\n")
        error!(msg, 406)
      end
      create_or_update_and_return_pub_hash(pub, author, authorship_hash)
    end # patch end
  end # class end
end
