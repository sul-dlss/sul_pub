# frozen_string_literal: true

## Notes on PublicationIdentifierNormalization
# - it uses lib/parse_identifier* to normalize data
# - it is not yet equipped to normalize all the identifier_type data
# - the base class in lib/parse_identifier.rb will handle anything thrown at it
#   - it does not change any data
#   - it detects blank PublicationIdentifier (which is deleted when `delete_blanks == true`)
# - exceptions and data modifications are logged into various log/*.log files
#

# As of 2017/11, these are the types that can be normalized:
# > select distinct identifier_type from publication_identifiers;
# doi - yes
# isbn - yes
# legacy_cap_pub_id - no
# pmc - no
# PMID - yes
# PublicationItemID - no
# SULPubId - no
# WoSItemID - no

old_level = ActiveRecord::Base.logger.level
ActiveRecord::Base.logger.level = 1

# the normalizer always logs analysis; it can also modify:
#   - PublicationIdentifier record
#   - PublicationIdentifier.Publication.pub_hash[:identifier]
normalizer = IdentifierNormalizer.new
normalizer.save_changes = true
normalizer.delete_blanks = true
normalizer.delete_invalid = true

PublicationIdentifier.where(identifier_type: 'doi').find_each(batch_size: 200) do |pub_id|
  normalizer.normalize_record(pub_id)
end

# ISBN normalization is pending a fix to https://github.com/sul-dlss/sul_pub/issues/393
# PublicationIdentifier.where(identifier_type: 'isbn').find_each(batch_size: 200) do |pub_id|
#   normalizer.normalize_record(pub_id)
# end

PublicationIdentifier.where(identifier_type: 'pmid').find_each(batch_size: 200) do |pub_id|
  normalizer.normalize_record(pub_id)
end

ActiveRecord::Base.logger.level = old_level
