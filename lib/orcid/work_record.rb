# frozen_string_literal: true

module Orcid
  ExternalIdentifier = Struct.new(:type, :value, :url, :relationship)
  Contributor = Struct.new(:name, :role)

  # Wrapper for the ORCID.org API work response.
  class WorkRecord
    def initialize(work_response)
      @work_response = work_response.with_indifferent_access
    end

    def put_code
      @put_code ||= work_response['put-code']
    end

    # the name of the source that provided the work to ORCID (e.g. "Crossref")
    def work_source
      @work_source ||= work_response.dig('source', 'source-name', 'value')
    end

    def work_type
      @work_type ||= work_response['type']
    end

    def external_ids
      @external_ids ||= work_response['external-ids']['external-id'].map do |external_id_response|
        external_id_value = external_id_response.dig('external-id-normalized', 'value') || external_id_response['external-id-value']
        ExternalIdentifier.new(external_id_response['external-id-type'],
                               external_id_value,
                               external_id_response.dig('external-id-url', 'value').presence,
                               external_id_response['external-id-relationship'])
      end.compact
    end

    def self_external_ids
      @self_external_ids ||= external_ids.select { |external_id| external_id.relationship == 'self' }
    end

    def part_of_external_ids
      @part_of_external_ids ||= external_ids.select { |external_id| external_id.relationship == 'part-of' }
    end

    def external_id_value(external_id_type)
      external_ids.find { |external_id| external_id.type == external_id_type }&.value
    end

    def title
      @title ||= work_response.dig('title', 'title', 'value')
    end

    def short_description
      @short_description ||= work_response['short-description']
    end

    def pub_year
      @pub_year ||= work_response.dig('publication-date', 'year', 'value')
    end

    def pub_month
      @pub_month ||= work_response.dig('publication-date', 'month', 'value')
    end

    def pub_day
      @pub_day ||= work_response.dig('publication-date', 'day', 'value')
    end

    def bibtex
      @bibtex ||= work_response.dig('citation', 'citation-type') == 'bibtex' ? work_response.dig('citation', 'citation-value') : nil
    end

    def citeproc
      @citeproc ||= begin
        bibtex ? BibTeX.parse(bibtex).to_citeproc.first : {}
      rescue BibTeX::ParseError
        {}
      end
    end

    def pages
      citeproc['page']
    end

    def publisher
      citeproc['publisher']
    end

    def contributors
      @contributors ||= work_response_contributors.presence || citeproc_contributors
    end

    def journal_title
      @journal_title ||= work_response.dig('journal-title', 'value')
    end

    def volume
      citeproc['volume']
    end

    def issue
      citeproc['issue']
    end

    private

    attr_reader :work_response

    def work_response_contributors
      Array(work_response.dig('contributors', 'contributor')).map do |contributor|
        Contributor.new(contributor.dig('credit-name', 'value'), contributor.dig('contributor-attributes', 'contributor-role'))
      end
    end

    def citeproc_contributors
      return [] unless bibtex

      Array(citeproc['author']).map do |author|
        Contributor.new([author['given'], author['family']].compact.join(' '), 'author')
      end
    end
  end
end
