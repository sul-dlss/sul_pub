# frozen_string_literal: true

require 'nokogiri'
require 'activerecord-import'

class SciencewireSourceRecord < ApplicationRecord
  # validates_uniqueness_of :sciencewire_id

  @@sw_conference_proceedings_types ||= Settings.sw_doc_type_mappings.conference.join('|')
  @@sw_book_types ||= Settings.sw_doc_type_mappings.book.join('|')

  include ActionView::Helpers::DateHelper

  ##
  # Instance methods

  def source_as_hash
    SciencewireSourceRecord.convert_sw_publication_doc_to_hash(publication_item)
  end

  # @return [ScienceWirePublication] PublicationItem object
  def publication
    @publication ||= ScienceWirePublication.new publication_item
  end

  # @return [Nokogiri::XML::Element] XML element for PublicationItem
  def publication_item
    @publication_item ||= publication_xml.at_xpath('//PublicationItem')
  end

  # @return [Nokogiri::XML::Document] XML document
  def publication_xml
    @publication_xml ||= Nokogiri::XML(source_data)
  end

  # Retrieve this PublicationItem from ScienceWire and update the pmid,
  # is_active, source_data and the source_fingerprint fields.
  # @return [Boolean] the return value from update!
  def sciencewire_update
    raise 'ScienceWire has been decommissioned!'
  end

  ##
  # Class methods

  def self.get_pub_by_pmid(pmid)
    sw_pub_hash = get_sciencewire_hash_for_pmid(pmid)
    return if sw_pub_hash.nil?

    pub = Publication.new(
      active: true,
      sciencewire_id: sw_pub_hash[:sw_id],
      pmid: pmid
    )
    pub.build_from_sciencewire_hash(sw_pub_hash)
    pub.sync_publication_hash_and_db
    pub.save
    pub
  end

  def self.get_pub_by_sciencewire_id(sciencewire_id)
    sw_pub_hash = get_sciencewire_hash_for_sw_id(sciencewire_id)
    return if sw_pub_hash.nil?

    pub = Publication.new(
      active: true,
      sciencewire_id: sciencewire_id,
      pmid: sw_pub_hash[:pmid]
    )
    pub.build_from_sciencewire_hash(sw_pub_hash)
    pub.sync_publication_hash_and_db
    pub.save
    pub
  end

  def self.get_sciencewire_hash_for_sw_id(sciencewire_id)
    sciencewire_source_record = find_by(sciencewire_id: sciencewire_id)
    sciencewire_source_record&.source_as_hash
  end

  def self.get_sciencewire_hash_for_pmid(pmid)
    sciencewire_source_record = find_by(pmid: pmid)
    sciencewire_source_record&.source_as_hash
  end

  def self.save_sw_source_record(sciencewire_id, pmid, incoming_sw_xml_as_string)
    existing_sw_source_record = find_by(
      sciencewire_id: sciencewire_id
    )
    if existing_sw_source_record.nil?
      new_source_fingerprint = get_source_fingerprint(incoming_sw_xml_as_string)
      attrs = {
        sciencewire_id: sciencewire_id,
        source_data: incoming_sw_xml_as_string,
        is_active: true,
        source_fingerprint: new_source_fingerprint
      }
      attrs[:pmid] = pmid if pmid.present?
      create(attrs)
    end
    # return true or false to indicate if new record was created or one already existed.
    existing_sw_source_record.nil?

    # elsif existing_sw_source_record.source_fingerprint != new_source_fingerprint
    #   existing_sw_source_record.update(
    #     pmid: pmid,
    #     source_data: incoming_sw_xml_as_string,
    #     is_active: true,
    #     source_fingerprint: new_source_fingerprint
    #    )
  end

  def self.get_source_fingerprint(sw_record_doc)
    Digest::SHA2.hexdigest(sw_record_doc)
  end

  def self.source_data_has_changed?(existing_sw_source_record, incoming_sw_source_doc)
    existing_sw_source_record.source_fingerprint != get_source_fingerprint(incoming_sw_source_doc)
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  def self.convert_sw_publication_doc_to_hash(publication)
    doi = extract_doi(publication)
    issn = extract_issn(publication)
    pmid = extract_pmid(publication)
    swid = extract_swid(publication)
    wosid = extract_wosid(publication)

    doi_identifier = { type: 'doi', id: doi, url: "#{Settings.DOI.BASE_URI}#{doi}" } if doi.present?
    issn_identifier = { type: 'issn', id: issn, url: Settings.SULPUB_ID.SEARCHWORKS_URI + issn } if issn.present?

    identifiers = []
    identifiers << { type: 'PMID', id: pmid, url: "#{Settings.PUBMED.ARTICLE_BASE_URI}#{pmid}" } if pmid.present?
    if wosid.present?
      identifiers << { type: 'WoSItemID', id: wosid,
                       url: "#{Settings.SCIENCEWIRE.ARTICLE_BASE_URI}#{wosid}" }
    end
    identifiers << { type: 'PublicationItemID', id: swid } if swid.present?
    identifiers << doi_identifier if doi.present?

    record_as_hash = {}
    record_as_hash[:provenance] = Settings.sciencewire_source
    record_as_hash[:sw_id] = swid
    record_as_hash[:pmid] = pmid if pmid.present?
    record_as_hash[:issn] = issn if issn.present?
    record_as_hash[:identifier] = identifiers

    record_as_hash[:title] = publication.xpath('Title').text if publication.xpath('Title').present?
    if publication.xpath('Abstract').present?
      record_as_hash[:abstract_restricted] =
        publication.xpath('Abstract').text
    end
    record_as_hash[:author] = publication.xpath('AuthorList').text.split('|').collect { |author| { name: author } }

    record_as_hash[:year] = publication.xpath('PublicationYear').text if publication.xpath('PublicationYear').present?
    record_as_hash[:date] = publication.xpath('PublicationDate').text if publication.xpath('PublicationDate').present?

    record_as_hash[:authorcount] = publication.xpath('AuthorCount').text if publication.xpath('AuthorCount').present?

    if publication.xpath('KeywordList').present?
      record_as_hash[:keywords_sw] =
        publication.xpath('KeywordList').text.split('|')
    end
    record_as_hash[:documenttypes_sw] = publication.xpath('DocumentTypeList').text.split('|')

    if publication.xpath('DocumentCategory').present?
      record_as_hash[:documentcategory_sw] =
        publication.xpath('DocumentCategory').text
    end
    sul_document_type = lookup_cap_doc_type_by_sw_doc_category(record_as_hash[:documentcategory_sw])
    record_as_hash[:type] = sul_document_type

    if publication.xpath('PublicationImpactFactorList').present?
      record_as_hash[:publicationimpactfactorlist_sw] =
        publication.xpath('PublicationImpactFactorList').text.split('|')
    end
    if publication.xpath('PublicationCategoryRankingList').present?
      record_as_hash[:publicationcategoryrankinglist_sw] =
        publication.xpath('PublicationCategoryRankingList').text.split('|')
    end
    if publication.xpath('NumberOfReferences').present?
      record_as_hash[:numberofreferences_sw] =
        publication.xpath('NumberOfReferences').text
    end
    if publication.xpath('TimesCited').present?
      record_as_hash[:timescited_sw_retricted] =
        publication.xpath('TimesCited').text
    end
    if publication.xpath('TimesNotSelfCited').present?
      record_as_hash[:timenotselfcited_sw] =
        publication.xpath('TimesNotSelfCited').text
    end
    if publication.xpath('AuthorCitationCountList').present?
      record_as_hash[:authorcitationcountlist_sw] =
        publication.xpath('AuthorCitationCountList').text
    end
    record_as_hash[:rank_sw] = publication.xpath('Rank').text if publication.xpath('Rank').present?
    if publication.xpath('OrdinalRank').present?
      record_as_hash[:ordinalrank_sw] =
        publication.xpath('OrdinalRank').text
    end
    if publication.xpath('NormalizedRank').present?
      record_as_hash[:normalizedrank_sw] =
        publication.xpath('NormalizedRank').text
    end
    if publication.xpath('NewPublicationItemID').present?
      record_as_hash[:newpublicationid_sw] =
        publication.xpath('NewPublicationItemID').text
    end
    record_as_hash[:isobsolete_sw] = publication.xpath('IsObsolete').text if publication.xpath('IsObsolete').present?

    if publication.xpath('CopyrightPublisher').present?
      record_as_hash[:publisher] =
        publication.xpath('CopyrightPublisher').text
    end
    record_as_hash[:city] = publication.xpath('CopyrightCity').text if publication.xpath('CopyrightCity').present?
    if publication.xpath('CopyrightStateProvince').present?
      record_as_hash[:stateprovince] =
        publication.xpath('CopyrightStateProvince').text
    end
    if publication.xpath('CopyrightCountry').present?
      record_as_hash[:country] =
        publication.xpath('CopyrightCountry').text
    end
    record_as_hash[:pages] = publication.xpath('Pagination').text if publication.xpath('Pagination').present?

    if sul_document_type == Settings.sul_doc_types.inproceedings
      conference_hash = {}
      if publication.xpath('ConferenceTitle').present?
        conference_hash[:name] =
          publication.xpath('ConferenceTitle').text
      end
      if publication.xpath('ConferenceStartDate').present?
        conference_hash[:startdate] =
          publication.xpath('ConferenceStartDate').text
      end
      if publication.xpath('ConferenceEndDate').present?
        conference_hash[:enddate] =
          publication.xpath('ConferenceEndDate').text
      end
      if publication.xpath('ConferenceCity').present?
        conference_hash[:city] =
          publication.xpath('ConferenceCity').text
      end
      if publication.xpath('ConferenceStateCountry').present?
        conference_hash[:statecountry] =
          publication.xpath('ConferenceStateCountry').text
      end
      record_as_hash[:conference] = conference_hash unless conference_hash.empty?
    elsif sul_document_type == Settings.sul_doc_types.book
      if publication.xpath('PublicationSourceTitle').present?
        record_as_hash[:booktitle] =
          publication.xpath('PublicationSourceTitle').text
      end
      record_as_hash[:pages] = publication.xpath('Pagination').text if publication.xpath('Pagination').present?
    end

    if sul_document_type == Settings.sul_doc_types.article || (sul_document_type == Settings.sul_doc_types.inproceedings && publication.xpath('Issue').present?)
      journal_hash = {}
      if publication.xpath('PublicationSourceTitle').present?
        journal_hash[:name] =
          publication.xpath('PublicationSourceTitle').text
      end
      journal_hash[:volume] = publication.xpath('Volume').text if publication.xpath('Volume').present?
      journal_hash[:issue] = publication.xpath('Issue').text if publication.xpath('Issue').present?
      if publication.xpath('ArticleNumber').present?
        journal_hash[:articlenumber] =
          publication.xpath('ArticleNumber').text
      end
      journal_hash[:pages] = publication.xpath('Pagination').text if publication.xpath('Pagination').present?
      journal_identifiers = []
      journal_identifiers << issn_identifier if issn.present?
      journal_hash[:identifier] = journal_identifiers
      record_as_hash[:journal] = journal_hash
    end

    # unless issn.blank? || publication.xpath('Issue').blank? || sul_document_type == Settings.sul_doc_types.article
    #   book_series_hash = {}
    #   book_series_hash[:identifier] = [issn_identifier]
    #   book_series_hash[:title] = publication.xpath('PublicationSourceTitle').text unless publication.xpath('PublicationSourceTitle').blank?
    #   book_series_hash[:volume] = publication.xpath('Volume').text unless publication.xpath('Volume').blank?
    #   record_as_hash[:series] = book_series_hash
    # end
    record_as_hash
  end

  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity
  def self.lookup_sw_doc_type(doc_type_list)
    doc_types = Array(doc_type_list)
    if doc_types.any? { |t| t =~ /^(#{@@sw_conference_proceedings_types})$/i }
      Settings.sul_doc_types.inproceedings
    elsif doc_types.any? { |t| t =~ /^(#{@@sw_book_types})$/i }
      Settings.sul_doc_types.book
    else
      Settings.sul_doc_types.article
    end
  end

  # Maps a ScienceWire `DocumentCategory` to a corresponding value in `Settings.sul_doc_types`.
  # The ScienceWire API documentation notes three valid values for the `DocumentCategory` field, i.e.:
  # - 'Conference Proceeding Document'
  # - 'Journal Document'
  # - 'Other'
  #
  # @param sw_doc_category [String] One of the document categories
  # @return [String] One of the `Settings.sul_doc_types`
  def self.lookup_cap_doc_type_by_sw_doc_category(sw_doc_category)
    return Settings.sul_doc_types.inproceedings if sw_doc_category == 'Conference Proceeding Document'

    Settings.sul_doc_types.article
  end

  def self.extract_pmid(doc)
    element = doc.xpath('PMID')
    element.nil? ? '' : element.text
  end

  def self.extract_swid(doc)
    element = doc.xpath('PublicationItemID')
    element.nil? ? '' : element.text
  end

  def self.extract_doi(doc)
    element = doc.xpath('DOI')
    element.nil? ? '' : element.text
  end

  def self.extract_issn(doc)
    element = doc.xpath('ISSN')
    element.nil? ? '' : element.text
  end

  def self.extract_wosid(doc)
    element = doc.at_xpath('WoSItemID')
    element.nil? ? '' : element.text
  end
end
