# frozen_string_literal: true

module Orcid
  ExternalIdentifier = Struct.new(:type, :value, :url)

  # Wrapper for the ORCID.org API work response.
  class WorkRecord
    def initialize(work_response)
      @work_response = work_response.with_indifferent_access
    end

    def put_code
      @put_code ||= work_response['put-code']
    end

    def work_type
      @work_type ||= work_response['type']
    end

    def external_ids
      @external_ids ||= work_response['external-ids']['external-id'].map do |external_id_response|
        next if external_id_response['external-id-relationship'] != 'self'

        external_id_value = external_id_response.dig('external-id-normalized', 'value') || external_id_response['external-id-value']
        ExternalIdentifier.new(external_id_response['external-id-type'], external_id_value, external_id_response['external-id-url'])
      end.compact
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

    private

    attr_reader :work_response
  end
end
