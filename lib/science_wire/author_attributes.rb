module ScienceWire
  ##
  # Attributes used for creating author search queries
  class AuthorAttributes
    attr_reader :last_name, :first_name, :middle_name, :email, :seed_list
    def initialize(last_name, first_name, middle_name, email, seed_list)
      @last_name = last_name
      @first_name = first_name
      @middle_name = middle_name
      @email = email
      @seed_list = seed_list
    end

    def first_name_initial
      first_name.to_s.strip[0].to_s
    end
  end
end
