# frozen_string_literal: true

module Agent
  ##
  # Author/Institution address details used for creating search queries
  class AuthorAddress
    attr_reader :line1, :line2, :city, :state, :country

    # @param [Hash] options query options
    # @option options [String] :line1 AddressLine1
    # @option options [String] :line2 AddressLine2
    # @option options [String] :city
    # @option options [String] :state
    # @option options [String] :country
    def initialize(options = {})
      @line1   = options[:line1].to_s.strip
      @line2   = options[:line2].to_s.strip
      @city    = options[:city].to_s.strip
      @state   = options[:state].to_s.strip
      @country = options[:country].to_s.strip
    end

    def to_xml
      @xml ||= begin
        xml = ''
        xml += "<AddressLine1>#{line1}</AddressLine1>" unless line1.empty?
        xml += "<AddressLine2>#{line2}</AddressLine2>" unless line2.empty?
        xml += "<City>#{city}</City>" unless city.empty?
        xml += "<State>#{state}</State>" unless state.empty?
        xml += "<Country>#{country}</Country>" unless country.empty?
        xml
      end
    end

    def ==(other)
      line1 == other.line1 &&
        line2 == other.line2 &&
        city == other.city &&
        state == other.state &&
        country == other.country
    end

    def empty?
      to_xml.strip.empty?
    end
  end
end
