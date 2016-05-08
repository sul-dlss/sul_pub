module ScienceWire
  ##
  # Attributes used for creating author search queries
  class AuthorName
    attr_reader :last, :first, :middle

    # @param last [String] last name
    # @param first [String] first name
    # @param middle [String] middle name
    def initialize(last = '', first = '', middle = '')
      @last = as_string last
      @first = as_string first
      @middle = as_string middle
    end

    def first_initial
      @first_initial ||= initial(first)
    end

    def middle_initial
      @middle_initial ||= initial(middle)
    end

    def full_name
      @full_name ||= begin
        return '' if last.empty? && first.empty?
        name = "#{last},#{first}"
        name += ",#{middle}" unless middle.empty?
        name
      end
    end

    def text_search_query
      @text_search_query ||= begin
        query = %("#{last},#{first}" or "#{last.upcase},#{first_initial}")
        query << name_query_middle(Regexp.last_match(1)) if middle =~ /^([[:alpha:]])/
        query
      end
    end

    def ==(other)
      last == other.last &&
      first == other.first &&
      middle == other.middle
    end

    private

      def name_query_middle(mid)
        " or \"#{last.upcase},#{first_initial}#{mid.upcase}\""
      end

      def as_string(param)
        param.to_s.strip
      end

      def initial(name)
        name[0].to_s.upcase
      end
  end
end
