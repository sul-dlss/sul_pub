# frozen_string_literal: true

require_relative 'identifier_parser'

# Parse the PMID identifiers in a PublicationIdentifier
class IdentifierParserPMID < IdentifierParser
  URI_PREFIX = 'https://www.ncbi.nlm.nih.gov/pubmed/'

  # Does the data validate?
  def valid?
    value.present? && uri.present?
  end

  # Extract a PMID value
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
    @extractor ||= Identifiers::PubmedId
  end

  def extract_value_from_uri
    # TO work around https://github.com/altmetric/identifiers/issues/19
    uri = pub_id[:identifier_uri]
    match = uri.nil? ? nil : uri.match(/(\d+)\z/)
    match.nil? ? nil : extractor.extract(match[1]).first
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log', 'identifier_parser_pmid.log'))
  end

  def match_type
    type.casecmp('pmid').zero?
  end
end
