require 'science_wire/publication_query'
require 'science_wire/recommendation'

module ScienceWire
  ##
  # The configurable client and preferred API for interacting with the
  # ScienceWire library from within sul-pub.
  class Client
    include ScienceWire::PublicationQuery
    include ScienceWire::Recommendation

    attr_accessor :licence_id, :host
    ##
    # @param [String] licence_id
    # @param [String] host
    def initialize(licence_id:, host:)
      @licence_id = licence_id
      @host = host
    end
  end
end
