# frozen_string_literal: true

require 'citeproc'
require 'csl/styles'

module Orcid
  # Maps from pub_hash to Orcid Work.
  class PubMapper
    # Maps to Orcid Work.
    # @param [Hash] pub_hash
    # @return [Hash] work
    def self.map(pub_hash)
      new(pub_hash).map
    end

    def initialize(pub_hash)
      @pub_hash = pub_hash
    end

    def map
      # TODO: Build complete work
      {
        type: map_type,
        visibility: 'public',
        title: map_title,
        'external-ids': map_ids,
        'short-description': pub_hash[:abstract],
        'publication-date': map_pub_date,
        citation: map_citation,
        contributors: map_contributors,
        'journal-title': map_journal
      }.compact
    end

    private

    attr_reader :pub_hash

    def work_type
      @work_type ||= PublicationTypeMapper.to_work_type(pub_hash[:type])
    end

    def map_type
      raise 'Unmapped publication type' unless work_type

      work_type
    end

    def map_title
      title = if work_type == 'book'
                pub_hash[:booktitle].presence || pub_hash[:title].presence
              else
                pub_hash[:title].presence
              end
      raise 'Title is required' unless title

      {
        title: {
          value: title
        }
      }
    end

    def map_ids
      ids = Array(pub_hash[:identifier]).map do |identifier|
        # Need a type and id
        next if identifier[:type].blank? || identifier[:id].blank?

        # Only mappable types.
        id_type = IdentifierTypeMapper.to_orcid_id_type(identifier[:type])
        next if id_type.nil?

        {
          'external-id-type' => id_type,
          'external-id-value' => identifier[:id],
          'external-id-url' => identifier[:url].presence,
          'external-id-relationship' => 'self'
        }.compact
      end.compact
      raise 'An identifier is required' if ids.empty?

      {
        'external-id' => ids
      }
    end

    def map_pub_date
      map_pub_date_from_date || map_pub_date_from_year
    end

    def map_pub_date_from_date
      date = DateTime.parse(pub_hash[:date])

      {
        year: { value: date.strftime('%Y') },
        month: { value: date.strftime('%m') },
        day: { value: date.strftime('%d') }
      }
    rescue StandardError
      nil
    end

    def map_pub_date_from_year
      return nil unless pub_hash[:year]&.match(/\d\d\d\d/)

      {
        year: { value: pub_hash[:year] },
        month: nil,
        day: nil
      }
    end

    def map_citation
      {
        "citation-type": 'bibtex',
        "citation-value": Csl::Citation.new(pub_hash).to_bibtex.strip
      }
    end

    def map_contributors
      {
        contributor: Array(pub_hash[:author]).map { |author| PubAuthorMapper.map(author) }
      }
    end

    def map_journal
      journal_title = case pub_hash[:type]
                      when 'article'
                        pub_hash.dig(:journal, :name)
                      when 'inproceedings'
                        pub_hash.dig(:conference, :name)
                      end
      return nil if journal_title.blank?

      { value: journal_title }
    end
  end
end
