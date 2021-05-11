# frozen_string_literal: true

# IdentifierNormalizer
# - normalize PublicationIdentifier data
# - uses lib/identifier_parser_[type] to normalize that type of identifier
# - the base class in lib/identifier_parser will handle anything thrown at it
#   - it does not change any data; it detects blank PublicationIdentifier
# - exceptions and data modifications are logged into various log/identifier*.log files
# - data is changed in two datasets
#   - PublicationIdentifier record
#   - PublicationIdentifier.Publication.pub_hash[:identifier]
class IdentifierNormalizer
  attr_accessor :delete_blanks, :delete_invalid, :save_changes

  # @param save_changes [Boolean] save changes (default: false)
  # @param delete_blanks [Boolean] delete empty identifiers (default: false)
  # @param delete_invalid [Boolean] delete invalid identifiers (default: false)
  def initialize(save_changes: false, delete_blanks: false, delete_invalid: false)
    @save_changes = save_changes
    @delete_blanks = delete_blanks
    @delete_invalid = delete_invalid
  end

  # @param pub_id [PublicationIdentifier]
  def normalize_record(pub_id)
    pub_id_update(pub_id)
  rescue IdentifierParserEmptyError
    pub_id_destroy(pub_id) if delete_blanks
  rescue IdentifierParserInvalidError
    pub_id_destroy(pub_id) if delete_invalid
  rescue StandardError => e
    logger.error e.inspect
  end

  private

  # Choose a parser that can handle the PublicationIdentifier.identifier_type
  # @param pub_id [PublicationIdentifier]
  # @return [IdentifierParser] a kind of IdentifierParser to handle the pub_id
  def identifier_parser(pub_id)
    case pub_id[:identifier_type].to_s.downcase
    when 'doi'
      IdentifierParserDOI.new(pub_id)
    when 'isbn'
      IdentifierParserISBN.new(pub_id)
    when 'pmid'
      IdentifierParserPMID.new(pub_id)
    else
      # this default parser will not normalize any data, but it can detect blank data
      IdentifierParser.new(pub_id)
    end
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/identifier_normalizer.log'))
  end

  # @param pub_id [PublicationIdentifier]
  def pub_id_destroy(pub_id)
    pub_id.destroy!
    pub_id.pub_hash_update(delete: true)
    pub_id.publication.save!
  end

  # @param pub_id [PublicationIdentifier]
  def pub_id_update(pub_id)
    parser = identifier_parser(pub_id)
    pub_id = parser.update if save_changes
    return unless pub_id.changed?

    pub_id.save!
    pub_id.publication.publication_identifiers.reload
    pub_id.pub_hash_update
    pub_id.publication.save!
  end
end
