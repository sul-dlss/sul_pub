require 'nokogiri'
require 'activerecord-import'

class SciencewireSourceRecord < ActiveRecord::Base
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
  # @return [Boolean] the return value from update_attributes!
  def sciencewire_update
    sw_record_doc = ScienceWireClient.new.get_sw_xml_source_for_sw_id(sciencewire_id)
    sw_pub = ScienceWirePublication.new sw_record_doc
    attrs = {}
    attrs[:pmid] = sw_pub.pmid unless sw_pub.pmid.blank?
    attrs[:is_active] = !sw_pub.obsolete?
    attrs[:source_data] = sw_pub.to_xml
    attrs[:source_fingerprint] = Digest::SHA2.hexdigest(sw_record_doc)
    update_attributes! attrs
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
    sciencewire_source_record = get_sciencewire_source_record_for_sw_id(sciencewire_id)
    sciencewire_source_record.source_as_hash unless sciencewire_source_record.nil?
  end

  def self.get_sciencewire_hash_for_pmid(pmid)
    sciencewire_source_record = get_sciencewire_source_record_for_pmid(pmid)
    sciencewire_source_record.source_as_hash unless sciencewire_source_record.nil?
  end

  def self.get_sciencewire_source_record_for_sw_id(sw_id)
    find_by(sciencewire_id: sw_id) || get_sciencewire_source_record_from_sciencewire_by_sw_id(sw_id)
  end

  def self.get_sciencewire_source_record_for_pmid(pmid)
    find_by(pmid: pmid) || get_sciencewire_source_record_from_sciencewire(pmid)
  end

  def self.get_sciencewire_source_record_from_sciencewire(pmid)
    get_and_store_sw_source_records([pmid])
    find_by(pmid: pmid)
  end

  def self.get_sciencewire_source_record_from_sciencewire_by_sw_id(sciencewire_id)
    get_and_store_sw_source_record_for_sw_id(sciencewire_id)
    find_by(sciencewire_id: sciencewire_id)
  end

  def self.get_and_store_sw_source_record_for_sw_id(sciencewire_id)
    sw_record_doc = ScienceWireClient.new.get_sw_xml_source_for_sw_id(sciencewire_id)
    pmid = extract_pmid(sw_record_doc)
    where(sciencewire_id: sciencewire_id).first_or_create(
      source_data: sw_record_doc.to_xml,
      is_active: true,
      pmid: pmid,
      source_fingerprint: Digest::SHA2.hexdigest(sw_record_doc)
    )
  end
  private_class_method :get_and_store_sw_source_record_for_sw_id

  # get and store sciencewire source records for pmid list
  def self.get_and_store_sw_source_records(pmids)
    sw_records_doc = ScienceWireClient.new.pull_records_from_sciencewire_for_pmids(pmids)
    count = 0
    source_records = []
    sw_records_doc.xpath('//PublicationItem').each do |sw_record_doc|
      pmid = extract_pmid(sw_record_doc)
      sciencewire_id = extract_swid(sw_record_doc)
      begin
        count += 1
        pmids.delete(pmid)
        source_records << SciencewireSourceRecord.new(
          sciencewire_id: sciencewire_id,
          source_data: sw_record_doc.to_xml,
          is_active: true,
          pmid: pmid,
          source_fingerprint: Digest::SHA2.hexdigest(sw_record_doc)
        )
      rescue => e
        NotificationManager.error(e, "Cannot create SciencewireSourceRecord: sciencewire_id: #{sciencewire_id}, pmid: #{pmid}", self)
      end
    end
    import source_records
  end
  private_class_method :get_and_store_sw_source_records

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
      attrs[:pmid] = pmid unless pmid.blank?
      create(attrs)
    end
    # return true or false to indicate if new record was created or one already existed.
    was_record_created = existing_sw_source_record.nil?
    was_record_created
    # elsif existing_sw_source_record.source_fingerprint != new_source_fingerprint
    #   existing_sw_source_record.update_attributes(
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

  def self.convert_sw_publication_doc_to_hash(publication)
    doi = extract_doi(publication)
    issn = extract_issn(publication)
    pmid = extract_pmid(publication)
    swid = extract_swid(publication)
    wosid = extract_wosid(publication)

    doi_identifier = { type: 'doi', id: doi, url: "#{Settings.DOI.BASE_URI}#{doi}" } unless doi.blank?
    issn_identifier = { type: 'issn', id: issn, url: Settings.SULPUB_ID.SEARCHWORKS_URI + issn } unless issn.blank?

    identifiers = []
    identifiers << { type: 'PMID', id: pmid, url: "#{Settings.PUBMED.ARTICLE_BASE_URI}#{pmid}" } unless pmid.blank?
    identifiers << { type: 'WoSItemID', id: wosid, url: "#{Settings.SCIENCEWIRE.ARTICLE_BASE_URI}#{wosid}" } unless wosid.blank?
    identifiers << { type: 'PublicationItemID', id: swid } unless swid.blank?
    identifiers << doi_identifier unless doi.blank?

    record_as_hash = {}
    record_as_hash[:provenance] = Settings.sciencewire_source
    record_as_hash[:sw_id] = swid
    record_as_hash[:pmid] = pmid unless pmid.blank?
    record_as_hash[:issn] = issn unless issn.blank?
    record_as_hash[:identifier] = identifiers

    record_as_hash[:title] = publication.xpath('Title').text unless publication.xpath('Title').blank?
    record_as_hash[:abstract_restricted] = publication.xpath('Abstract').text unless publication.xpath('Abstract').blank?
    record_as_hash[:author] = publication.xpath('AuthorList').text.split('|').collect { |author| { name: author } }

    record_as_hash[:year] = publication.xpath('PublicationYear').text unless publication.xpath('PublicationYear').blank?
    record_as_hash[:date] = publication.xpath('PublicationDate').text unless publication.xpath('PublicationDate').blank?

    record_as_hash[:authorcount] = publication.xpath('AuthorCount').text unless publication.xpath('AuthorCount').blank?

    record_as_hash[:keywords_sw] = publication.xpath('KeywordList').text.split('|') unless publication.xpath('KeywordList').blank?
    record_as_hash[:documenttypes_sw] = publication.xpath('DocumentTypeList').text.split('|')

    record_as_hash[:documentcategory_sw] = publication.xpath('DocumentCategory').text unless publication.xpath('DocumentCategory').blank?
    sul_document_type = lookup_cap_doc_type_by_sw_doc_category(record_as_hash[:documentcategory_sw])
    record_as_hash[:type] = sul_document_type

    record_as_hash[:publicationimpactfactorlist_sw] = publication.xpath('PublicationImpactFactorList').text.split('|') unless publication.xpath('PublicationImpactFactorList').blank?
    record_as_hash[:publicationcategoryrankinglist_sw] = publication.xpath('PublicationCategoryRankingList').text.split('|') unless publication.xpath('PublicationCategoryRankingList').blank?
    record_as_hash[:numberofreferences_sw] = publication.xpath('NumberOfReferences').text unless publication.xpath('NumberOfReferences').blank?
    record_as_hash[:timescited_sw_retricted] = publication.xpath('TimesCited').text unless publication.xpath('TimesCited').blank?
    record_as_hash[:timenotselfcited_sw] = publication.xpath('TimesNotSelfCited').text unless publication.xpath('TimesNotSelfCited').blank?
    record_as_hash[:authorcitationcountlist_sw] = publication.xpath('AuthorCitationCountList').text unless publication.xpath('AuthorCitationCountList').blank?
    record_as_hash[:rank_sw] = publication.xpath('Rank').text unless publication.xpath('Rank').blank?
    record_as_hash[:ordinalrank_sw] = publication.xpath('OrdinalRank').text unless publication.xpath('OrdinalRank').blank?
    record_as_hash[:normalizedrank_sw] = publication.xpath('NormalizedRank').text unless publication.xpath('NormalizedRank').blank?
    record_as_hash[:newpublicationid_sw] = publication.xpath('NewPublicationItemID').text unless publication.xpath('NewPublicationItemID').blank?
    record_as_hash[:isobsolete_sw] = publication.xpath('IsObsolete').text unless publication.xpath('IsObsolete').blank?

    record_as_hash[:publisher] = publication.xpath('CopyrightPublisher').text unless publication.xpath('CopyrightPublisher').blank?
    record_as_hash[:city] = publication.xpath('CopyrightCity').text unless publication.xpath('CopyrightCity').blank?
    record_as_hash[:stateprovince] = publication.xpath('CopyrightStateProvince').text unless publication.xpath('CopyrightStateProvince').blank?
    record_as_hash[:country] = publication.xpath('CopyrightCountry').text unless publication.xpath('CopyrightCountry').blank?
    record_as_hash[:pages] = publication.xpath('Pagination').text unless publication.xpath('Pagination').blank?

    if sul_document_type == Settings.sul_doc_types.inproceedings
      conference_hash = {}
      conference_hash[:name] = publication.xpath('ConferenceTitle').text unless publication.xpath('ConferenceTitle').blank?
      conference_hash[:startdate] = publication.xpath('ConferenceStartDate').text unless publication.xpath('ConferenceStartDate').blank?
      conference_hash[:enddate] = publication.xpath('ConferenceEndDate').text unless publication.xpath('ConferenceEndDate').blank?
      conference_hash[:city] = publication.xpath('ConferenceCity').text unless publication.xpath('ConferenceCity').blank?
      conference_hash[:statecountry] = publication.xpath('ConferenceStateCountry').text unless publication.xpath('ConferenceStateCountry').blank?
      record_as_hash[:conference] = conference_hash unless conference_hash.empty?
    elsif sul_document_type == Settings.sul_doc_types.book
      record_as_hash[:booktitle] = publication.xpath('PublicationSourceTitle').text unless publication.xpath('PublicationSourceTitle').blank?
      record_as_hash[:pages] = publication.xpath('Pagination').text unless publication.xpath('Pagination').blank?
    end

    if sul_document_type == Settings.sul_doc_types.article || (sul_document_type == Settings.sul_doc_types.inproceedings && !publication.xpath('Issue').blank?)
      journal_hash = {}
      journal_hash[:name] = publication.xpath('PublicationSourceTitle').text unless publication.xpath('PublicationSourceTitle').blank?
      journal_hash[:volume] = publication.xpath('Volume').text unless publication.xpath('Volume').blank?
      journal_hash[:issue] = publication.xpath('Issue').text unless publication.xpath('Issue').blank?
      journal_hash[:articlenumber] = publication.xpath('ArticleNumber').text unless publication.xpath('ArticleNumber').blank?
      journal_hash[:pages] = publication.xpath('Pagination').text unless publication.xpath('Pagination').blank?
      journal_identifiers = []
      journal_identifiers << issn_identifier unless issn.blank?
      journal_identifiers << doi_identifier unless doi.blank?
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

  def self.lookup_sw_doc_type(doc_type_list)
    doc_types = Array(doc_type_list)
    type = if doc_types.any? { |t| t =~ /^(#{@@sw_conference_proceedings_types})$/i }
             Settings.sul_doc_types.inproceedings
           elsif doc_types.any? { |t| t =~ /^(#{@@sw_book_types})$/i }
             Settings.sul_doc_types.book
           else
             Settings.sul_doc_types.article
           end
    type
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
