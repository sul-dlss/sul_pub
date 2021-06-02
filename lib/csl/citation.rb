# frozen_string_literal: true

require 'citeproc/ruby'

module Csl
  class Citation
    attr_reader :pub_hash

    delegate :to_apa_citation, :to_mla_citation, :to_chicago_citation, :to_bibtex, to: :renderer

    # @param pub_hash [Hash] a Publication.pub_hash
    def initialize(pub_hash)
      @pub_hash = pub_hash
    end

    # Generate all citations
    # @return [Hash]
    def citations
      {
        apa_citation: to_apa_citation,
        mla_citation: to_mla_citation,
        chicago_citation: to_chicago_citation
      }
    end

    def csl_doc
      @csl_doc ||= Csl::Mapper.new(pub_hash).csl_doc
    end

    private

    def renderer
      @renderer ||= CitationRenderer.new(citation_item)
    end

    def citation_item
      @citation_item ||= begin
        item = CiteProc::CitationItem.new(id: 'sulpub')
        item.data = CiteProc::Item.new(csl_doc.deep_dup)
        item
      end
    end
  end
end
