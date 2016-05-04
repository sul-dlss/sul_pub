module ScienceWire
  ##
  # Attributes used for creating author search queries
  class AuthorAttributes
    attr_reader :name, :email, :institution, :seed_list, :start_date, :end_date

    # @param name [AuthorName]
    # @param email [String]
    # @param seed_list [Array<Integer>]
    # @param institution [String|AuthorInstitution]
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
        name.is_a?(AuthorName) ? name : AuthorName.new
      end

      def init_institution(institution)
        if institution.is_a? AuthorInstitution
          institution
        elsif institution.is_a? String
          # set the institution name
          AuthorInstitution.new(institution)
        else
          # set a default institution
          AuthorInstitution.new
        end
      end
  end
end
