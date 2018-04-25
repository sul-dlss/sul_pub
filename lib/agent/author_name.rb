module Agent
  # Attributes used for creating author search queries
  class AuthorName
    attr_reader :last, :first, :middle

    # @param last [String, #to_s] last name
    # @param first [String, #to_s] first name
    # @param middle [String, #to_s] middle name
    def initialize(last = '', first = '', middle = '')
      @last = last.to_s.strip
      @first = first.to_s.strip
      @middle = middle.to_s.strip
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
    # @return [String] name(s) to be queried in an OR (disjunction) query
    def text_search_query
      text_search_terms.map { |x| "\"#{x}\"" }.join(' or ')
    end

    def text_search_terms
      @text_search_terms ||=
        [first_name_query, middle_name_query].flatten.reject(&:empty?).uniq
    end

    def ==(other)
      last == other.last &&
        first == other.first &&
        middle == other.middle
    end

    private

      # Name variants for:
      # 'Lastname,Firstname' or
      # 'Lastname,FirstInitial'
      # @return [Array<String>|String] names
      def first_name_query
        return '' if last.empty? && first.empty?
        query =  ["#{last_name},#{first_name}"]
        query += ["#{last_name},#{first_initial}"] if Settings.HARVESTER.USE_FIRST_INITIAL
        query
      end

      # Name variants for:
      # 'Lastname,Firstname,Middlename' or
      # 'Lastname,Firstname,MiddleInitial' or
      # 'Lastname,FirstInitial,MiddleInitial'
      # @return [Array<String>|String] names
      def middle_name_query
        return '' unless middle =~ /^[[:alpha:]]/
        query =  ["#{last_name},#{first_name},#{middle_name}", "#{last_name},#{first_name},#{middle_initial}"]
        query += ["#{last_name},#{first_initial}#{middle_initial}", "#{last_name},#{first_initial},#{middle_initial}"] if Settings.HARVESTER.USE_FIRST_INITIAL
        query
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
        name.gsub(/\b[[:alpha:]]+/) { |w| w =~ PARTICLE_REGEX ? w : w.capitalize }
      end
  end
end
