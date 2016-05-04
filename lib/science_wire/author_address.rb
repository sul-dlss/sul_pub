module ScienceWire
  ##
  # Author/Institution address details used for creating search queries
  class AuthorAddress
    attr_reader :line1, :line2, :city, :state, :country
    # @param options [Hash] options:
    #   :line1 [String]
    #   :line2 [String]
    #   :city [String]
    #   :state [String]
    #   :country [String]
    def initialize(options = {})
      @line1 = as_string options[:line1]
      @line2 = as_string options[:line2]
      @city = as_string options[:city]
      @state = as_string options[:state]
      @country = as_string options[:country]
    end

    def to_xml
      xml = ''
      xml += "<AddressLine1>#{line1}</AddressLine1>" unless line1.empty?
      xml += "<AddressLine2>#{line2}</AddressLine2>" unless line2.empty?
      xml += "<City>#{city}</City>" unless city.empty?
      xml += "<State>#{state}</State>" unless state.empty?
      xml += "<Country>#{country}</Country>" unless country.empty?
      xml
    end

    def ==(other)
      line1 == other.line1 &&
      line2 == other.line2 &&
      city == other.city &&
      state == other.state &&
      country == other.country
    end

    private

      def as_string(param)
        param.to_s.strip
      end
  end
end
