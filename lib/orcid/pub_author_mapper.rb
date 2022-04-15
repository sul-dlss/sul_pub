# frozen_string_literal: true

module Orcid
  # Maps from pub_hash author to Orcid Contributor.
  class PubAuthorMapper
    SUL_PUB_ROLE_TO_ORCID_ROLE = {
      'book_editor' => 'editor',
      'investigator' => 'principal-investigator'
    }.freeze

    IGNORED_SUL_PUB_ROLES = %w[
      book_corp
      corp
    ].freeze

    ORCID_ROLES = %w[
      author
      assignee
      editor
      chair-or-translator
      co-investigator
      co-inventor
      graduate-student
      other-inventor
      principal-investigator
      postdoctoral-researcher
      support-staff
    ].freeze

    # Maps to Orcid Contributor.
    # @param [Hash] author_hash author
    # @return [Hash|nil] contributor
    def self.map(author_hash)
      new(author_hash).map
    end

    def initialize(author_hash)
      @author_hash = author_hash
    end

    def map
      return if IGNORED_SUL_PUB_ROLES.include?(author_hash[:role])

      return if map_credit_name.blank?

      {
        'contributor-orcid': nil,
        'credit-name': {
          value: map_credit_name.truncate(150) # ORCID has a max length of 150 for this field
        },
        'contributor-email': nil,
        'contributor-attributes': {
          'contributor-sequence': nil,
          'contributor-role': map_role
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
      return unless name
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
      return if name_part.blank?

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

    def map_role
      role = author_hash[:role].presence
      orcid_role = SUL_PUB_ROLE_TO_ORCID_ROLE.fetch(role, role || 'author')

      return unless ORCID_ROLES.include?(orcid_role)

      orcid_role
    end
  end
end
