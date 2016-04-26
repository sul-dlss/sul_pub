module ScienceWire
  ##
  # Attributes used for creating author search queries
  class AuthorAttributes
    attr_reader :last_name, :first_name, :middle_name, :email, :seed_list
    def initialize(last_name, first_name, middle_name, email, seed_list)
      @last_name = last_name.to_s
      @first_name = first_name.to_s
      @middle_name = middle_name.to_s
      @email = email.to_s
      @seed_list = seed_list
    end

    def first_name_initial
      first_name.strip[0].to_s
    end
  end
end
