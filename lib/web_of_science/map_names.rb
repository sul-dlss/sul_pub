# frozen_string_literal: true

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

    attr_reader :names, :author_count

    # Extract content from record, try not to hang onto the entire record
    # @param rec [WebOfScience::Record]
    def extract(rec)
      super
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
      return name if name[:full_name].blank? && name[:display_name].blank?

      name_to_process = name[:full_name] || name[:display_name] # prefer full_name but accept display_name if full_name is missing
      last, given = name_to_process.split(',').map(&:strip)
      first, middle = given.strip.split(/\s+/) if given.present?
      name[:last_name] = last
      name[:given_name] = given
      name[:first_name] = first if first.present?
      name[:middle_name] = middle if middle.present?
      name[:name] = "#{name[:last_name]},#{name[:first_name]},#{name[:middle_name]}" # full name in the older style format used by Profiles/CAP
      name
    end

    # Parse the WOS names and return a Hash compatible with Csl::AuthorName
    # @return [Hash]
    def wos_name(name)
      # look for the case where the first_name is the initials, with first and middle initials combined
      # e.g. first_name = "RB", should be first_name = "R", middle_name = "B"
      match = name[:first_name].to_s.match(/\A([A-Z])([A-Z])/)
      if match
        name[:first_name] = match[1]
        name[:middle_name] ||= match[2]
      end
      # look for the case where the first name includes the middle initial optionally followed by a period
      # e.g. first_name = "Russel B.", should be first_name = "Russel", middle_name = "B"
      if name[:first_name].present?
        name[:first_name] = name[:first_name].gsub(/\s[[:upper:]]\.?\z/) do |s|
          name[:middle_name] = s.strip.chomp('.') # remove trailing spaces and periods
          ''
        end
      end
      # full name in the older style format used by Profiles/CAP
      name[:name] = "#{name[:last_name] || name[:display_name] || name[:full_name]},#{name[:first_name]},#{name[:middle_name]}"
      name
    end
  end
end
