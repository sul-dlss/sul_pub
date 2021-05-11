# frozen_string_literal: true

require 'citeproc/ruby'
# You can install more recent styles using the 'csl-styles' gem or you can just
# download the styles you need (just point CSL::Style.root to the directory and
# you can load any style with just its name using CSL::Style.load).
require 'csl/styles'

module Csl
  class Citation
    attr_reader :csl_renderer, :pub_hash

    CSL_STYLE_APA = CSL::Style.load('apa')
    CSL_STYLE_MLA = CSL::Style.load('modern-language-association')

    CSL_STYLE_CHICAGO = CSL::Style.load('chicago-author-date')
    CSL_STYLE_CHICAGO_ET_AL = begin
      # Modify the bibliography attributes so it uses 'et al.' after 5 authors
      style_et_al = CSL::Style.load('chicago-author-date')
      style_et_al.bibliography.attributes['et-al-min'] = 1
      style_et_al.bibliography.attributes['et-al-use-first'] = 5
      style_et_al
    end

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

    # Generates a new render instance every time, so it has no history of any prior citations.
    # When it has history, it can assume that subsequent citations can refer to earlier citations,
    # which has a different style for the subsequent citations.
    # @param csl_citation_data [Hash] a CSL citation document
    # @param csl_style [CSL::Style] a CSL citation style
    # @return [String] a bibliographic citation
    def generate_csl_citation(csl_citation_data, csl_style)
      item = CiteProc::CitationItem.new(id: 'sulpub')
      item.data = CiteProc::Item.new(csl_citation_data.deep_dup)
      csl_renderer = CiteProc::Ruby::Renderer.new(format: 'html')
      csl_renderer.render item, csl_style.bibliography
    end

    def to_chicago_citation
      if csl_doc['author'].count > 5
        generate_csl_citation(csl_doc, CSL_STYLE_CHICAGO_ET_AL)
      else
        generate_csl_citation(csl_doc, CSL_STYLE_CHICAGO)
      end
    end

    def to_mla_citation
      generate_csl_citation(csl_doc, CSL_STYLE_MLA)
    end

    def to_apa_citation
      generate_csl_citation(csl_doc, CSL_STYLE_APA)
    end

    def csl_doc
      @csl_doc ||= Csl::Mapper.new(pub_hash).csl_doc
    end
  end
end
