# frozen_string_literal: true

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
        type: 'journal-article',
        visibility: 'public',
        title: map_title,
        'external-ids' => map_ids
      }
    end

    private

    attr_reader :pub_hash

    def map_title
      raise 'Title is required' if pub_hash[:title].blank?

      {
        title: {
          value: pub_hash[:title]
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
  end
end