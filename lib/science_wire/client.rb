require 'science_wire/api'

module ScienceWire
  ##
  # The configurable client and preferred API for interacting with the
  # ScienceWire library from within sul-pub.
  class Client
    include ScienceWire::API

    attr_accessor :license_id, :host
    ##
    # @param [String] license_id
    # @param [String] host
    def initialize(license_id:, host:)
      @license_id = license_id
      @host = host
    end
  end
end
