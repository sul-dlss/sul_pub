# frozen_string_literal: true

module Orcid
  # Maps from Orcid Work to pub_hash.
  class WorkMapper
    # Maps to pub_hash.
    # @param [Orcid::WorkRecord] work
    # @return [Hash] pub_hash
    def self.map(work)
      new(work).map
    end

    def initialize(work)
      @work = work
    end

    def map
      # TODO: Build complete pub_hash
      {
        type: PublicationTypeMapper.to_pub_type(work.work_type),
        title: work.title,
        identifier: map_identifiers,
        abstract: work.short_description,
        provenance: 'orcid',
        doi: work.external_id_value('doi'),
        isbn: work.external_id_value('isbn'),
        issn: work.external_id_value('issn'),
        wos_uid: work.external_id_value('wosuid'),
        pmid: work.external_id_value('pmid')
      }.compact
    end

    private

    attr_reader :work

    def map_identifiers
      work.external_ids.map do |external_id|
        { type: IdentifierTypeMapper.to_sul_pub_id_type(external_id.type), id: external_id.value, url: external_id.url }.compact
      end
    end
  end
end
