module WebOfScience

  # Map WOS record data into the SUL PubHash data
  class MapNames < Mapper

    class << self
      # Convert authors into CSL authors
      # @param [Array<Hash>] names
      # @return [Array<Hash>] CSL authors names
      def authors_to_csl(names)
        authors = names.select { |name| name[:role] =~ /author/i }
        csl_names(authors)
      end

      # Convert editors into CSL editors
      # @param [Array<Hash>] names
      # @return [Array<Hash>] CSL editors names
      def editors_to_csl(names)
        editors = names.select { |name| name[:role] =~ /editor/i }
        csl_names(editors)
      end

      # CSL names
      # @param [Array<Hash>] names
      # @return [Array<Hash>] CSL names
      def csl_names(names)
        names.map do |name|
          Csl::AuthorName.new(
            lastname: name[:last_name],
            firstname: name[:first_name],
            middlename: name[:middle_name]
          ).to_csl_author
        end.compact
      end
    end

    # publication authors
    # @return [Hash]
    def pub_hash
      # - use names, with role, to include 'author' and other roles, possibly 'editor' also
      {
        author: names,
        authorcount: author_count
      }
    end

    private

      attr_reader :names
      attr_reader :author_count

      # Extract content from record, try not to hang onto the entire record
      # @param rec [WebOfScience::Record]
      def extract(rec)
        super(rec)
        @names = extract_names(rec)
        @author_count = names.count { |name| name[:role] == 'author' }
      end

      # Parse the WOS names and return a Hash compatible with Csl::AuthorName
      # @return [Hash]
      def extract_names(rec)
        fields = %w[display_name first_name middle_name last_name full_name initials role]
        rec.names.map do |name|
          name = name.slice(*fields).symbolize_keys
          case rec.database
          when 'MEDLINE'
            medline_name(name)
          when 'WOS'
            wos_name(name)
          else
            name
          end
        end
      end

      # Parse the MEDLINE names and return a Hash compatible with Csl::AuthorName
      # @return [Hash]
      def medline_name(name)
        # full_name has the form "LastName, GivenName" where GivenName is space delimited
        # display_name and full_name are often, if not always, the same
        # initials is a smashed set of initial letters, with no delimiters
        last, given = name[:full_name].split(',').map(&:strip)
        first, middle = given.strip.split(/\s+/)
        name[:last_name] = last
        name[:given_name] = given
        name[:first_name] = first
        name[:middle_name] = middle if middle.present?
        name
      end

      # Parse the WOS names and return a Hash compatible with Csl::AuthorName
      # @return [Hash]
      def wos_name(name)
        match = name[:first_name].to_s.match(/\A([A-Z])([A-Z])/)
        if match
          # first_name is the initials, with first and middle initials combined
          name[:first_name] = match[1]
          name[:middle_name] ||= match[2]
        end
        name
      end
  end
end
