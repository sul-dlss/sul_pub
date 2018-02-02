module WebOfScience

  # Find or create contributions for existing Web of Science publications
  # Also finds or creates contributions for existing PublicationIdentifiers
  module Contributions

    # Find any matching contributions by author and WOS-UID; create a contribution for any
    # existing publication without one for the author in question.
    # @param author [Author]
    # @param uids [Array<String>]
    # @return [Array<String>] uids that already have a contribution
    def author_contributions(author, uids)
      contrib_uids = []
      Publication.where(wos_uid: uids).find_each do |pub|
        contrib = find_or_create_contribution(author, pub)
        contrib_uids << pub.wos_uid if contrib.persisted?
      end
      contrib_uids
    end

    # Find any matching contributions by author and WOS-UID; create a contribution for any
    # existing publication without one for the author in question.
    # @param author [Author]
    # @param uid [String]
    # @return [Contribution, nil]
    def author_contribution(author, uid)
      pub = Publication.find(wos_uid: uid)
      return if pub.nil?
      find_or_create_contribution(author, pub)
    end

    # Find or create a new contribution to a publication for author.
    # @param [Author]
    # @param [Publication]
    # @return [Contribution]
    def find_or_create_contribution(author, publication)
      contrib = publication.contributions.find_or_initialize_by(author_id: author.id)
      create_contribution(author, contrib) unless contrib.persisted?
      contrib
    end

    # Save a new contribution to a WOS-UID publication for author.
    # @param author [Author]
    # @param contrib [Contribution]
    # @return [Boolean]
    def create_contribution(author, contrib)
      contrib.assign_attributes(
        cap_profile_id: author.cap_profile_id,
        featured: false, status: 'new', visibility: 'private'
      )
      contrib.save!
      # Add the pub_hash[:authorship] data to the publication
      contrib.publication.pubhash_needs_update!
      contrib.publication.save!
    rescue ActiveRecord::ActiveRecordError => err
      message = "Failed to create contribution for author: #{author.id}, pub: #{contrib.publication.id}"
      NotificationManager.error(err, message, self)
      false
    end

    # Does record have a contribution for this author? (based on matching PublicationIdentifiers)
    # Note: must use unique identifiers, don't use ISSN or similar series level identifiers
    # @param [Author] author
    # @param [WebOfScience::Record] record
    # @return [Boolean]
    def found_contribution?(author, record)
      contribution_by_identifier?(author, 'WosUID', record.uid) ||
        contribution_by_identifier?(author, 'WosItemID', record.wos_item_id) ||
        contribution_by_identifier?(author, 'doi', record.doi) ||
        contribution_by_identifier?(author, 'pmid', record.pmid)
    end

    # Find any matching contribution by author and PublicationIdentifier
    # @param author [Author]
    # @param type [String]
    # @param value [String]
    # @return [Boolean] contribution exists
    def contribution_by_identifier?(author, type, value)
      contrib = contribution_by_identifier(author, type, value)
      contrib.nil? ? false : contrib.persisted?
    end

    # Find any matching contribution by author and PublicationIdentifier
    # @param author [Author]
    # @param type [String]
    # @param value [String]
    # @return [Contribution, nil]
    def contribution_by_identifier(author, type, value)
      pub_id = publication_identifier(type, value)
      return if pub_id.nil?
      find_or_create_contribution(author, pub_id.publication)
    end

    # Is there a PublicationIdentifier matching the type and value?
    # @param type [String]
    # @param value [String]
    # @return [PublicationIdentifier, nil]
    def publication_identifier(type, value)
      return if type.blank? || value.blank?
      pub_ids = PublicationIdentifier.where(identifier_type: type, identifier_value: value)
      pub_ids.empty? ? nil : pub_ids.first
    end

  end
end
