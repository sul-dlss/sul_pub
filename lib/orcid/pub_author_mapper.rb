# frozen_string_literal: true

module Orcid
  # Maps from pub_hash author to Orcid Contributor.
  class PubAuthorMapper
    # Maps to Orcid Contributor.
    # @param [Hash] author_hash author
    # @return [Hash] contributor
    def self.map(author_hash)
      new(author_hash).map
    end

    def initialize(author_hash)
      @author_hash = author_hash
    end

    def map
      {
        "contributor-orcid": nil,
        "credit-name": {
          value: map_credit_name
        },
        "contributor-email": nil,
        "contributor-attributes": {
          "contributor-sequence": nil,
          "contributor-role": author_hash[:role].presence || 'author'
        }
      }
    end

    private

    attr_reader :author_hash

    def map_credit_name
      clean_name(author_hash[:name].presence) ||
        author_hash[:full_name].presence ||
        author_hash[:display_name].presence ||
        joined_name
    end

    def clean_name(name)
      # Some legacy names are misformatted, e.g., Clemens,Samuel,L
      return nil unless name
      return name unless name.match(/\S,\S/) && name.count(',') == 2

      parts = name.split(',')
      last_name = parts[0]
      first_name = clean_name_part(parts[1])
      middle_name = clean_name_part(parts[2])

      clean_name = last_name
      clean_name += ", #{first_name}" if first_name
      clean_name += " #{middle_name}" if middle_name
      clean_name
    end

    def clean_name_part(name_part)
      return nil if name_part.blank?

      return name_part if name_part.length != 1 || name_part.match(/ \S$/)

      "#{name_part}."
    end

    def joined_name
      [first_name, middle_name, last_name].compact.join(' ')
    end

    def first_name
      author_hash[:first_name].presence ||
        author_hash[:firstname].presence ||
        author_hash[:given_name].presence ||
        author_hash[:initials].presence
    end

    def middle_name
      author_hash[:middle_name].presence || author_hash[:middlename].presence
    end

    def last_name
      author_hash[:last_name].presence || author_hash[:lastname].presence
    end
  end
end
