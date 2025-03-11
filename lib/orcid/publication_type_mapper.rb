# frozen_string_literal: true

module Orcid
  # Maps work / publication types between ORCID and SUL-PUB.
  class PublicationTypeMapper
    # Note that this is limited to the work types for which mapping is supported.
    PUB_TYPE_TO_WORK_TYPE = {
      'article' => 'journal-article',
      'book' => 'book',
      'caseStudy' => 'research-tool',
      'inbook' => 'book-chapter',
      'inproceedings' => 'conference-paper'
    }.freeze

    # @return [String] ORCID work type or nil if no matching
    def self.to_work_type(pub_type)
      PUB_TYPE_TO_WORK_TYPE[pub_type]
    end

    # @return [String] SUL-PUB id type or nil if no matching
    def self.to_pub_type(work_type)
      PUB_TYPE_TO_WORK_TYPE.invert[work_type]
    end

    # @return [String] true if valid mapped work type (from ORCID to sul-pub).
    def self.work_type?(work_type)
      PUB_TYPE_TO_WORK_TYPE.value?(work_type)
    end
  end
end
