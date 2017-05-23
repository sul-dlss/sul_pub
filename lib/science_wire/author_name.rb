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
      @first_initial ||= initial(first_name)
    end

    def first_name
      @first_name ||= proper_name(first)
    end

    def middle_initial
      @middle_initial ||= initial(middle_name)
    end

    def middle_name
      @middle_name ||= proper_name(middle)
    end

    def last_name
      @last_name ||= proper_name(last)
    end

    def full_name
      @full_name ||= begin
        return '' if last.empty? && first.empty?
        name = "#{last_name},#{first_name}"
        name += ",#{middle_name}" unless middle.empty?
        name
      end
    end

    # Generate name variations for the PublicationQuery:TextSearch:QueryPredicate;
    # the search is not case sensitive.  The most permissive variant that will
    # match the most publications is likely 'Lastname,FirstInitial' and using
    # an 'or' conjuction is likely to generate results that mostly match this variant,
    # but additional variants might add something when using an 'ExactMatch' search.
    def text_search_query
      @text_search_query ||= begin
        names = [first_name_query, middle_name_query].flatten
        names.delete_if {|name| name.to_s.empty? }
        names.uniq.join(' or ')
      end
    end

    def ==(other)
      last == other.last &&
      first == other.first &&
      middle == other.middle
    end

    private

      # Add the name variants for:
      # 'Lastname,Firstname' or
      # 'Lastname,FirstInitial'
      # @return names [Array<String>|String]
      def first_name_query
        return '' if last.empty? && first.empty?
        [
          "\"#{last_name},#{first_name}\"",
          "\"#{last_name},#{first_initial}\""
        ]
      end

      # Add the name variants for:
      # 'Lastname,Firstname,Middlename' or
      # 'Lastname,Firstname,MiddleInitial' or
      # 'Lastname,FirstInitial,MiddleInitial'
      # @return names [Array<String>|String]
      def middle_name_query
        return '' unless middle =~ /^[[:alpha:]]/
        [
          "\"#{last_name},#{first_name},#{middle_name}\"",
          "\"#{last_name},#{first_name},#{middle_initial}\"",
          "\"#{last_name},#{first_initial},#{middle_initial}\""
        ]
      end

      def as_string(param)
        param.to_s.strip
      end

      # Some names may contain particles, e.g. the
      # PubmedSourceRecord#author_to_hash checks for particles like:
      # /el-|el |da |de |del |do |dos |du |le /
      # This method will skip particles to extract the first upper
      # case letter or return '', e.g.
      # initial('dos Santos') => "S"
      # initial('del Ray') => "R"
      # initial('del ray') => ""
      def initial(name)
        name.scan(/[[:upper:]]/).first.to_s
      end

      PARTICLE_REGEX = /^el$|^da$|^de$|^del$|^do$|^dos$|^du$|^le$/

      # If a name contains any capital letters, return it as is; otherwise
      # return a capitalized form of the name, taking into account some
      # particles that should not be capitalized.  For example,
      # proper_name('Maria el-Solano'.downcase) => "Maria el-Solano"
      # proper_name('Berners-Lee'.downcase) => "Berners-Lee"
      def proper_name(name)
        return name if name =~ /[[:upper:]]/
        name.gsub(/\b[[:alpha:]]+/) {|w| w =~ PARTICLE_REGEX ? w : w.capitalize }
      end
  end
end