# frozen_string_literal: true

require_relative 'identifier_parser'

# Parse the ISBN identifiers in a PublicationIdentifier
class IdentifierParserISBN < IdentifierParser
  # Does the data validate?
  def valid?
    value.present? # ISBN has no URI
  end

  # Extract a value
  # @return [String|nil]
  def value
    @value ||= extract_value
  end

  private

  # Compose a URI
  # @return [String|nil]
  def compose_uri
    nil # ISBN has no URI
  end

  def extractor
    @extractor ||= Identifiers::ISBN
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/identifier_parser_isbn.log'))
  end

  def match_type
    type.casecmp('isbn').zero?
  end
end
