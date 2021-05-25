# frozen_string_literal: true

module Orcid
  # Maps from pub_hash author to Orcid External-Identifier.
  class PubIdentifierMapper
    # Maps to Orcid External-Identifier.
    # @param [Hash] pub_hash
    # @return [Array<Hash>] external-identifiers
    def self.map(pub_hash)
      new(pub_hash).map
    end

    def initialize(pub_hash)
      @pub_hash = pub_hash
    end

    def map
      ids = map_identifiers(pub_hash[:identifier], 'self') +
            map_identifiers(pub_hash.dig(:journal, :identifier), 'part-of') +
            map_identifiers(pub_hash.dig(:conference, :identifier), 'part-of') +
            map_identifiers(pub_hash.dig(:series, :identifier), 'part-of')

      raise PubMapper::PubMapperError, 'An identifier is required' if ids.empty?

      clean_issns(ids)
      clean_part_of(ids)

      {
        'external-id' => ids
      }.with_indifferent_access
    end

    private

    attr_reader :pub_hash

    def map_identifiers(pub_hash_identifiers, relationship)
      Array(pub_hash_identifiers).map do |identifier|
        # Need a type and id
        next if identifier[:type].blank? || identifier[:id].blank?

        # Only mappable types.
        id_type = IdentifierTypeMapper.to_orcid_id_type(identifier[:type])
        next if id_type.nil?

        {
          'external-id-type' => id_type,
          'external-id-value' => identifier[:id],
          'external-id-url' => map_url(identifier),
          'external-id-relationship' => relationship
        }
      end.compact
    end

    def map_url(identifier)
      return nil if identifier[:url].blank? || identifier[:url].include?('searchworks.stanford.edu')

      identifier[:url]
    end

    def clean_issns(ids)
      # Remove ISSN from self if matches ISSN for part-of
      to_delete_ids = ids.select do |id|
        id['external-id-relationship'] == 'self' &&
          id['external-id-type'] == 'issn' &&
          id?(ids, 'issn', id['external-id-value'], 'part-of')
      end
      to_delete_ids.each { |id| ids.delete(id) }
    end

    def clean_part_of(ids)
      # Remove ids if part-of id matches self id
      to_delete_ids = ids.select do |id|
        id['external-id-relationship'] == 'part-of' &&
          id?(ids, id['external-id-type'], id['external-id-value'], 'self')
      end
      to_delete_ids.each { |id| ids.delete(id) }
    end

    def id?(ids, type, value, relationship)
      ids.any? { |id| id['external-id-type'] == type && id['external-id-value'] == value && id['external-id-relationship'] == relationship }
    end
  end
end
