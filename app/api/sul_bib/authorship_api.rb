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

      def create_or_update_and_return_pub_hash(pub, author, authorship)
        # A publication manages a contribution update, so that it can update
        # the data in the pub.pub_hash field. This is the most painful data
        # modeling aspect of this application.  It maintains a Hash in a
        # Publication.pub_hash field, breaking the elegant design of a RDBMS.
        contrib = pub.contributions.find_or_initialize_by(author_id: author.id)
        contrib.assign_attributes(authorship.merge(cap_profile_id: author.cap_profile_id, author_id: author.id))
        pub.pubhash_needs_update! if contrib.persisted?
        begin
          contrib.save!
          # Save the publication so it will sync the contribution into the pub.pub_hash[:authorship] array.
          pub.save!
        rescue ActiveRecord::ActiveRecordError => e
          error!(e.inspect, 500)
        end
        # Return the entire pub_hash rather than just the contribution.  The
        # contribution should be in the pub_hash[:authorship] array.
        pub.pub_hash
      end

      # Find an existing Author by 'cap_profile_id' or 'sul_author_id'.  This
      # helper can retrieve a CAP profile if an author does not exist yet.
      def get_author(cap_profile_id, sul_author_id)
        if cap_profile_id.blank? && sul_author_id.blank?
          msg = "The request is missing 'sul_author_id' and 'cap_profile_id'."
          logger.error msg
          error!(msg, 400)
        end
        if cap_profile_id
          get_cap_author(cap_profile_id)
        elsif sul_author_id
          get_sul_author(sul_author_id)
        end
      end

      def get_cap_author(cap_profile_id)
        # The author must be identified in the Author table; do not trust the
        # cap_profile_id field in the Contribution table.
        authors = Author.where(cap_profile_id: cap_profile_id)
        if authors.length == 1
          profile = authors.first
        elsif authors.empty?
          begin
            profile = Author.fetch_from_cap_and_create(cap_profile_id)
          rescue => e
            msg = "SULCAP cannot retrieve cap_profile_id: #{cap_profile_id}\n"
            msg += e.message
            status = 404
          end
        else
          # Hitting this block of code should be a cause for concern.  This
          # should be impossible if unique constraint is applied to Authors.
          msg = "SULCAP has multiple records for cap_profile_id: #{cap_profile_id}\n"
          msg += authors.to_json
          status = 500
        end
        profile || begin
          if msg.nil?
            msg = "SULCAP has no record for cap_profile_id: #{cap_profile_id}"
            status = 404
          end
          logger.error msg
          error!(msg, status)
        end
      end

      def get_sul_author(sul_author_id)
        Author.find(sul_author_id)
      rescue ActiveRecord::RecordNotFound
        msg = "SULCAP has no record for sul_author_id: #{sul_author_id}"
        logger.error msg
        error!(msg, 404)
      end

      # Double check the author contains a cap_profile_id and, if one is
      # specified in the request, ensure we have the right one!
      def check_author_ids(author, cap_profile_id)
        unless cap_profile_id.blank?
          if author.cap_profile_id != cap_profile_id.to_i
            if author.cap_profile_id.blank?
              # The author was found by 'sul_author_id' and it has
              # never had a 'cap_profile_id' assigned to it, so do it now.
              author.cap_profile_id = cap_profile_id.to_i
              author.save
            else
              # The author was found by 'sul_author_id' and it has
              # a different 'cap_profile_id' assigned to it, barf!
              msg = "SULCAP has an author record with a different cap_profile_id\n"
              msg += "Found     cap_profile_id: #{author.cap_profile_id} in sul_author_id: #{author.id}\n"
              msg += "Requested cap_profile_id: #{cap_profile_id}"
              logger.error msg
              error!(msg, 500)
            end
          end
        end
        return unless author.cap_profile_id.blank?
        # When POST only contains a sul_author_id and the author found has no cap_profile_id, log a warning.
        logger.warn "SULCAP sul_author_id #{author.id} has no cap_profile_id"
      end

      # Find an existing contribution by author/publication
      def get_contribution(author, sul_pub_id)
        contributions = Contribution.where(
          author_id: author.id,
          publication_id: sul_pub_id
        )
        if contributions.empty?
          msg = "SULCAP has no contributions by the author:#{author.id} for the publication:#{sul_pub_id}"
          logger.error msg
          error!(msg, 404)
        elsif contributions.length > 1
          # Hitting this block of code should be a cause for concern.
          msg = "SULCAP has multiple contributions by the author:#{author.id} for the publication:#{sul_pub_id}"
          logger.error msg
          error!(msg, 500)
        end
        contributions.first
      end

      # Find an existing SUL publication or, if it doesn't exist, it
      # may be fetched from PubMed (pmid) or ScienceWire (sw_id).
      def get_publication(sul_pub_id, pmid, sw_id)
        if sul_pub_id.blank? && pmid.blank? && sw_id.blank?
          msg = 'There is no valid publication identifier: sul_pub_id || pmid || sw_id.'
          logger.error msg
          error!(msg, 400)
        end
        if sul_pub_id
          begin
            Publication.find(sul_pub_id)
          rescue ActiveRecord::RecordNotFound
            msg = "The SUL:#{sul_pub_id} publication does not exist."
            logger.error msg
            error!(msg, 404)
          end
        elsif pmid
          pub = Publication.find_or_create_by_pmid(pmid)
          if pub.nil?
            msg = "The PMID:#{pmid} was not found either locally or at PubMed."
            logger.error msg
            error!(msg, 404)
          end
          pub
        elsif sw_id
          pub = Publication.find_or_create_by_sciencewire_id(sw_id)
          if pub.nil?
            msg = "The ScienceWire:#{sw_id} publication was not found either locally or at ScienceWire."
            logger.error msg
            error!(msg, 404)
          end
          pub
        end
      end # get_publication
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
      request_body_unparsed = env['api.request.input']
      logger.info('POST Contribution JSON: ')
      logger.info(request_body_unparsed.to_s)

      # Find or create an author
      author = get_author(
        params[:cap_profile_id],
        params[:sul_author_id]
      )
      check_author_ids(author, params[:cap_profile_id])

      # Now find an existing sul publication or, if it doesn't exist, it
      # may be fetched from PubMed (pmid) or ScienceWire (sw_id).
      pub = get_publication(
        params[:sul_pub_id],
        params[:pmid],
        params[:sw_id]
      )

      # We've now got the author and pub, validate the authorship and create or
      # update the contribution.  (When a request only requires an update, it
      # should use the PATCH method below.)
      authorship_hash = contrib_attr
      # Contribution.valid_fields? will confirm  the authorship fields are
      # present and valid; the GrapeAPI checks the presence of required params.
      Contribution.valid_fields?(authorship_hash) ||
        error!('You have not supplied a valid authorship record.', 406)
      create_or_update_and_return_pub_hash(pub, author, authorship_hash)
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
      request_body_unparsed = env['api.request.input']
      logger.info('PATCH Contribution JSON: ')
      logger.info(request_body_unparsed.to_s)

      # Find an existing author
      author = get_author(
        params[:cap_profile_id],
        params[:sul_author_id]
      )
      check_author_ids(author, params[:cap_profile_id])

      # The Grape API requires the sul_pub_id parameter, so there should be no
      # need to check or validate it here.
      sul_pub_id = params[:sul_pub_id]

      # Find an existing contribution by author/publication
      contrib = get_contribution(author, sul_pub_id)
      pub = contrib.publication

      # We've now got the contribution, gather the new attributes.  In a PATCH
      # request, it's OK if some of them are missing; validate only the
      # fields provided.  When check for 'featured', use .nil? because it
      # is allowed to have a `false` value.
      authorship_hash = contrib_attr.with_indifferent_access
      !authorship_hash[:featured].nil? ||
        authorship_hash[:status].present? ||
        authorship_hash[:visibility].present? ||
        error!("At least one authorship attribute is required: 'featured', 'status', 'visibility'.", 406)
      unless authorship_hash[:featured].nil?
        Contribution.featured_valid?(authorship_hash) ||
          error!("The 'featured' param is invalid: #{authorship_hash[:featured]}.", 406)
      end
      if authorship_hash[:status].present?
        Contribution.status_valid?(authorship_hash) ||
          error!("The 'status' param is invalid: #{authorship_hash[:status]}.", 406)
      end
      if authorship_hash[:visibility].present?
        Contribution.visibility_valid?(authorship_hash) ||
          error!("The 'visibility' param is invalid: #{authorship_hash[:visibility]}.", 406)
      end
      create_or_update_and_return_pub_hash(pub, author, authorship_hash)
    end # patch end
  end # class end
end
