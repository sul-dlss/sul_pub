module Agent
  ##
  # Attributes used for creating author search queries
  class AuthorInstitution
    attr_reader :name, :address

    # @param name [String]
    # @param address [Hash] with optional fields:
    #   :line1, :line2, :city, :state, :country
    def initialize(name = '', address = nil)
      @name = name.to_s.strip
      @address = init_address(address)
    end

    # Normalize the name by removing some common words
    # that do little to distinguish the institution.
    def normalize_name
      @normalize_name ||= begin
        return '' if name.empty?

        exclude = %w(corporation institute organization university
                     all and of the).join('|')
        tmp = name.dup
        tmp.gsub!(/#{exclude}/i, '')
        tmp.gsub!(/\s+/, ' ')
        tmp.strip!
        tmp.downcase # it's not case sensitive
      end
    end

    def ==(other)
      normalize_name == other.normalize_name &&
        address == other.address
    end

    private

    def init_address(address)
      return address if address.is_a?(Agent::AuthorAddress)

      # set the address line 1, or an empty (default)
      Agent::AuthorAddress.new(address.is_a?(String) ? { line1: address } : {})
    end
  end
end
