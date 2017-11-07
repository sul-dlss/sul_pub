require_relative 'identifier_parser'

# Parse the DOI identifiers in a PublicationIdentifier
class IdentifierParserDOI < IdentifierParser

  URI_PREFIX = 'http://dx.doi.org/'.freeze

  # Does the data validate?
  def valid?
    value.present? && uri.present?
  end

  # Extract a DOI value
  # @return [String|nil]
  def value
    @value ||= extract_value
  end

  private

    # Compose a URI
    # @return [String|nil]
    def compose_uri
      return nil if value.blank?
      URI_PREFIX + value
    end

    def extractor
      @extractor ||= Identifiers::DOI
    end

    def logger
      @logger ||= Logger.new(Rails.root.join('log', 'identifier_parser_doi.log'))
    end

    def match_type
      type.casecmp('doi').zero?
    end
end
