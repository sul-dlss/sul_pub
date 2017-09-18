module SulBib
  class PublicationsAPI < Grape::API
    version 'v1', using: :header, vendor: 'sul', cascade: false
    default_format :json

    helpers do
      # Used in GET and PUT to return an existing publication record
      # @param id [String] A unique publication ID
      # @return pub [Publication] If found, returns a Publication record
      #         returns an error if the publication is not found or if it has
      #         been deleted (unless the request is a 'DELETE')
      def publication_find(id)
        begin
          pub = Publication.find(id)
        rescue ActiveRecord::RecordNotFound
          error!({ 'error' => 'No such publication', 'detail' => "You've requested a non-existant publication." }, 404)
        end
        error!('Gone - old resource deleted.', 410) if pub.deleted? && !request.delete?
        pub
      end

      # Check for existing authors.
      # @param authorship_list [Array<Hash>]
      # @return status [boolean] true if any of the authors exist.
      def existing_authors?(authorship_list)
        # At least one of the authors in the authorship array must exist.
        return false if authorship_list.nil?
        authorship_list.any? { |auth| Contribution.authorship_valid?(auth) }
      end

      # Check for existing authors or create new authors with a CAP profile ID.
      # @param authorship_list [Array<Hash>]
      # @return status [boolean] true if any authors exist or are created.
      def validate_or_create_authors(authorship_list)
        # At least one of the authors in the authorship array must exist or have
        # a CAP profile that is used to create a new SULCAP author.
        return false if authorship_list.nil?
        status = false
        authorship_list.each do |authorship|
          # Contribution.authorship_valid? confirms existing authors;
          # it does not create new authors.
          if Contribution.authorship_valid?(authorship)
            status = true
          else
            cap_profile_id = authorship[:cap_profile_id]
            unless cap_profile_id.blank?
              Author.fetch_from_cap_and_create(cap_profile_id)
              status = true
            end
          end
        end
        status
      end

      def original_source
        @original_source ||= env['api.request.input']
      end
    end

    desc 'POST - CREATE A NEW MANUAL PUBLICATION'
    content_type :json, 'application/json'
    parser :json, BibJSONParser
    params do
      requires :pub_hash
    end
    post do
      logger.info('adding new manual publication from BibJSON')
      logger.info(original_source)
      pub_hash = params[:pub_hash]
      fingerprint = Digest::SHA2.hexdigest(original_source)
      existing_record = UserSubmittedSourceRecord.where(source_fingerprint: fingerprint).first
      if existing_record
        logger.info("Found existing record for #{fingerprint}: #{existing_record.inspect}; redirecting.")
        # the GRAPE redirect method issues a 303 (when original request is not a get, and a 302 for a get)
        # and sets the Location header to the specified URL
        # So, this next line returns a 303 with Location equal to the pub's URI
        redirect env['REQUEST_URI'] + '/' + existing_record.publication_id.to_s
      else
        if !validate_or_create_authors(pub_hash[:authorship])
          error!('You have not supplied a valid authorship record.', 406)
        end
        pub = Publication.build_new_manual_publication(pub_hash, original_source, Settings.cap_provenance)
        pub.save
        pub.reload
        logger.debug("Created new publication #{pub.inspect}")
        header 'Location', env['REQUEST_URI'].to_s + '/' + pub.id.to_s
        pub.pub_hash
      end
    end

    desc 'PUT - UPDATE A MANUAL PUBLICATION'
    content_type :json, 'application/json'
    parser :json, BibJSONParser
    params do
      requires :id
      requires :pub_hash
    end
    put ':id' do
      # the last known etag must be sent in the 'if-match' header, returning `412 Precondition Failed` if etags don't match,
      # and a `428 Precondition Required` if the if-match header isn't supplied
      new_pub = params[:pub_hash]
      old_pub = publication_find(params[:id])
      case
      when !old_pub.sciencewire_id.blank? || !old_pub.pmid.blank?
        error!({ 'error' => 'This record may not be modified.  If you had originally entered details for the record, it has been superceded by a central record.', 'detail' => 'missing widget' }, 403)
      when !validate_or_create_authors(new_pub[:authorship])
        error!('You have not supplied a valid authorship record.', 406)
      end

      logger.info("Update manual publication #{old_pub.inspect} with BibJSON:")
      logger.info(original_source)

      old_pub.update_manual_pub_from_pub_hash(new_pub, original_source, Settings.cap_provenance)
      old_pub.save
      old_pub.reload
      logger.debug("resulting pub hash: #{old_pub.pub_hash}")
      old_pub.pub_hash
    end

    desc 'GET - READ A SINGLE RECORD'
    params do
      requires :id
    end
    get ':id' do
      pub = publication_find(params[:id])
      pub.pub_hash
    end

    desc 'DELETE - MARK A RECORD AS OBSOLETE'
    params do
      requires :id
    end
    delete ':id' do
      pub = publication_find(params[:id])
      pub.delete!
    end

  end
end
