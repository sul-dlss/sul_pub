require 'faraday'
require 'identifiers'

# https://github.com/altmetric/identifiers
#
# Identifiers::DOI.extract('example: 10.123/abcd.efghi')
# # => ["10.123/abcd.efghi"]

module DOI

  # Note:  DOI has moved from http://dx.doi.org to http://doi.org
  DOI_PREFIX = 'https://doi.org/'.freeze

  class << self

    # @param [String] doi value or URL
    # @return [String, nil] DOI name if it is extracted, nil otherwise
    def doi_name(doi)
      Identifiers::DOI.extract(doi).first
    rescue StandardError
      nil
    end

    # @param [String] doi value or URL
    # @return [String, nil] DOI URL if it is found, nil otherwise
    def doi_url(doi)
      value = doi_name(doi)
      return if value.nil?
      DOI::DOI_PREFIX + value
    end

    # @param [String] doi_url
    # @return [Boolean]
    def doi_found?(doi_url)
      ! doi_location(doi_url).nil?
    end

    # @param [String] doi_url
    # @return [String, nil] doi location
    def doi_location(doi_url)
      response = Faraday.head doi_url
      return nil if response.status >= 400
      response.headers['location']
    end
  end
end
