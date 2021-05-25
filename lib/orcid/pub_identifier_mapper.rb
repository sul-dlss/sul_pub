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

      raise 'An identifier is required' if ids.empty?

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
          'external-id-url' => identifier[:url].presence,
          'external-id-relationship' => relationship
        }.compact
      end.compact
    end
  end
end
