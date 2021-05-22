# frozen_string_literal: true

# You can install more recent styles using the 'csl-styles' gem or you can just
# download the styles you need (just point CSL::Style.root to the directory and
# you can load any style with just its name using CSL::Style.load).
require 'csl/styles'

module Csl
  # Renders a citation from a
  class CitationRenderer
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

    CSL_STYLE_BIBTEX = CSL::Style.load('bibtex')

    # @param [CiteProc::CitationItem] citation_item
    def initialize(citation_item)
      @citation_item = citation_item
    end

    def to_chicago_citation
      if author_count > 5
        generate_csl_citation(CSL_STYLE_CHICAGO_ET_AL)
      else
        generate_csl_citation(CSL_STYLE_CHICAGO)
      end
    end

    def to_mla_citation
      generate_csl_citation(CSL_STYLE_MLA)
    end

    def to_apa_citation
      generate_csl_citation(CSL_STYLE_APA)
    end

    def to_bibtex
      generate_csl_citation(CSL_STYLE_BIBTEX)
    end

    private

    attr_reader :citation_item

    # Generates a new render instance every time, so it has no history of any prior citations.
    # When it has history, it can assume that subsequent citations can refer to earlier citations,
    # which has a different style for the subsequent citations.
    # @param csl_style [CSL::Style] a CSL citation style
    # @return [String] a bibliographic citation
    def generate_csl_citation(csl_style)
      csl_renderer = CiteProc::Ruby::Renderer.new(format: 'html')
      csl_renderer.render citation_item, csl_style.bibliography
    end

    def author_count
      citation_item.data[:author]&.to_citeproc&.size || 0
    end
  end
end
