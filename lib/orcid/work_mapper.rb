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
        pmid: work.external_id_value('pmid'),
        year: work.pub_year,
        date: map_pub_date,
        apa_citation: map_apa_citation,
        mla_citation: map_mla_citation,
        chicago_citation: map_chicago_citation,
        author: map_authors,
        journal: map_journal
      }.compact
    end

    private

    attr_reader :work

    def map_identifiers
      work.external_ids.map do |external_id|
        { type: IdentifierTypeMapper.to_sul_pub_id_type(external_id.type), id: external_id.value, url: external_id.url }.compact
      end
    end

    def map_pub_date
      return nil unless work.pub_year && work.pub_month && work.pub_day

      "#{work.pub_year}-#{work.pub_month}-#{work.pub_day}T00:00:00"
    end

    def map_apa_citation
      return nil unless work.bibtex

      renderer.to_apa_citation
    end

    def map_mla_citation
      return nil unless work.bibtex

      renderer.to_mla_citation
    end

    def map_chicago_citation
      return nil unless work.bibtex

      renderer.to_chicago_citation
    end

    def map_authors
      work.contributors.map do |contributor|
        { name: contributor.name, role: contributor.role }.compact
      end
    end

    def map_journal
      return nil unless work.journal_title && work.work_type == 'journal-article'

      {
        name: work.journal_title
      }
    end

    def renderer
      @renderer ||= begin
        citeproc = BibTeX.parse(work.bibtex).to_citeproc.first
        item = CiteProc::CitationItem.new(id: 'sulpub')
        item.data = CiteProc::Item.new(citeproc)
        Csl::CitationRenderer.new(item)
      end
    end
  end
end
