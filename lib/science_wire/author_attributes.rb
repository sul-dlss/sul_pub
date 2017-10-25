module ScienceWire
  ##
  # Attributes used for creating author search queries
  class AuthorAttributes
    attr_reader :name, :email, :institution, :seed_list, :start_date, :end_date

    # @param name [Agent::AuthorName]
    # @param email [String, #to_s]
    # @param seed_list [Array<Integer>]
    # @param institution [String, Agent::AuthorInstitution]
    # @param start_date [Date]
    # @param end_date [Date]
    def initialize(name, email, seed_list = [], institution = nil, start_date = nil, end_date = nil)
      @name = init_name(name)
      @email = email.to_s
      @seed_list = seed_list
      @institution = init_institution(institution)
      @start_date = start_date
      @end_date = end_date
    end

    private

      def init_name(name)
        name.is_a?(Agent::AuthorName) ? name : Agent::AuthorName.new
      end

      def init_institution(institution)
        return institution if institution.is_a?(Agent::AuthorInstitution)
        # else set institution name, or nil (default)
        Agent::AuthorInstitution.new(institution.is_a?(String) ? institution : nil)
      end
  end
end
