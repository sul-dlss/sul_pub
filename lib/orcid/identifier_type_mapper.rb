# frozen_string_literal: true

module Orcid
  # Maps identifier types between ORCID and SUL-PUB.
  class IdentifierTypeMapper
    # These map what ORCID calls an identifier to what we call the same identifier
    ORCID_ID_TYPE_TO_SUL_PUB_ID_TYPE = {
      'pmid' => 'PMID',
      'wosuid' => 'WosUID'
    }.freeze

    # These map what we call an identifier to what ORCID calls the same identifier
    SUL_PUB_ID_TYPE_TO_ORCID_ID_TYPE = {
      'eissn' => 'issn',
      'PMID' => 'pmid',
      'WosUID' => 'wosuid'
    }.freeze

    # From https://pub.orcid.org/v3.0/identifiers
    # These are the known ID types that we can push to ORCID
    # Our publications need to have one of these known identifiers in order to push to ORCID
    ORCID_ID_TYPES = %w[
      agr
      ark
      arxiv
      asin
      asin-tld
      authenticusid
      bibcode
      cba
      cienciaiul
      cit
      ctx
      dnb
      doi
      eid
      ethos
      grant_number
      hal
      handle
      hir
      isbn
      issn
      jfm
      jstor
      kuid
      lccn
      lensid
      mr
      oclc
      ol
      osti
      other-id
      pat
      pdb
      pmc
      pmid
      ppr
      proposal-id
      rfc
      rrid
      source-work-id
      ssrn
      uri
      urn
      wosuid
      zbl
    ].freeze

    # @return [String] ORCID id type or nil if no matching
    def self.to_orcid_id_type(sul_pub_id_type)
      id_type = SUL_PUB_ID_TYPE_TO_ORCID_ID_TYPE.fetch(sul_pub_id_type, sul_pub_id_type)

      return nil unless ORCID_ID_TYPES.include?(id_type)

      id_type
    end

    # Note that SUL-PUB id types is not a controlled list. Thus, the ORCID id type will be used in most cases.
    # @return [String] SUL-PUB id type
    def self.to_sul_pub_id_type(orcid_id_type)
      ORCID_ID_TYPE_TO_SUL_PUB_ID_TYPE.fetch(orcid_id_type, orcid_id_type)
    end
  end
end
