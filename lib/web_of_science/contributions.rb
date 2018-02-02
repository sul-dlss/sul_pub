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
      publication.contributions.find_or_create_by!(author_id: author.id) do |contrib|
        contrib.assign_attributes(
          cap_profile_id: author.cap_profile_id,
          featured: false, status: 'new', visibility: 'private'
        )
        publication.pubhash_needs_update! # Add to pub_hash[:authorship]
        publication.save! # contrib.save! not needed
      end
    rescue ActiveRecord::ActiveRecordError => err
      message = "Failed to find/create contribution for author: #{author.id}, pub: #{publication.id}"
      NotificationManager.error(err, message, self)
    end

    # Does record have a contribution for this author? (based on matching PublicationIdentifiers)
    # Note: must use unique identifiers, don't use ISSN or similar series level identifiers
    # We search for all PubIDs at once instead of serial queries.  No need to hit the same table multiple times.
    # @param [Author] author
    # @param [WebOfScience::Record] record
    # @return [::Contribution, nil] a matched or newly minted Contribution
    def matching_contribution(author, record)
      pub = Publication.joins(:publication_identifiers).where(
        "publication_identifiers.identifier_value IS NOT NULL AND (
         (publication_identifiers.identifier_type = 'WosUID' AND publication_identifiers.identifier_value = ?) OR
         (publication_identifiers.identifier_type = 'WosItemID' AND publication_identifiers.identifier_value = ?) OR
         (publication_identifiers.identifier_type = 'doi' AND publication_identifiers.identifier_value = ?) OR
         (publication_identifiers.identifier_type = 'pmid' AND publication_identifiers.identifier_value = ?))",
         record.uid, record.wos_item_id, record.doi, record.pmid
      ).order(
        "CASE
          WHEN publication_identifiers.identifier_type = 'WosUID' THEN 0
          WHEN publication_identifiers.identifier_type = 'WosItemID' THEN 1
          WHEN publication_identifiers.identifier_type = 'doi' THEN 2
          WHEN publication_identifiers.identifier_type = 'pmid' THEN 3
         END"
      ).first
      return unless pub
      find_or_create_contribution(author, pub)
    end

    # Find any matching contribution by author and PublicationIdentifier
    # @param author [Author]
    # @param type [String]
    # @param value [String]
    # @return [Boolean] contribution exists
    def contribution_by_identifier?(author, type, value)
      return false if type.blank? || value.blank?
      pub = Publication.includes(:publication_identifiers)
                       .find_by("publication_identifiers.identifier_type": type, "publication_identifiers.identifier_value": value)
      return false unless pub
      find_or_create_contribution(author, pub) ? true : false
    end
  end
end
