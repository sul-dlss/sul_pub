require 'science_wire/api'

module ScienceWire
  ##
  # The configurable client and preferred API for interacting with the
  # ScienceWire library from within sul-pub.
  class Client
    include ScienceWire::API

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
