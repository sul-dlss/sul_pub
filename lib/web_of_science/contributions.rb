module WebOfScience

  # Find or create contributions for existing Web of Science publications
  # Also finds or creates contributions for existing PublicationIdentifiers
  module Contributions

    # Find any matching contributions by author and WOS-UID; create a contribution for any
    # existing publication without one for the author in question.
    # @param author [Author]
    # @param uids [Array<String>]
    # @return [Array<String>] uids guaranteed to have matching Publication and Contribution
    def author_contributions(author, uids)
      Publication.where(wos_uid: uids).find_each.map do |pub|
        pub.contributions.find_or_create_by!(author_id: author.id) do |contrib|
          contrib.assign_attributes(
            cap_profile_id: author.cap_profile_id,
            featured: false, status: 'new', visibility: 'private'
          )
          pub.pubhash_needs_update! # Add to pub_hash[:authorship]
          pub.save! # contrib.save! not needed
        end
        pub.wos_uid
      end
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
  end
end
