class ScienceWirePublication
  attr_reader :xml_doc

  # @return [String] XML for PublicationItem
  delegate :to_xml, to: :xml_doc

  # @param [Nokogiri::XML::Element] a PublicationItem
  def initialize(xml_doc)
    @xml_doc = xml_doc
    raise(ArgumentError, 'xml_doc must be a <PublicationItem> Nokogiri::XML::Element') unless valid?
  end

  # ------------------------------------------------------------
  # Publication Identifiers

  # @return [String] DOI
  def doi
    element_text 'DOI'
  end

  # International Standard Serial Number
  # @return [String] ISSN
  def issn
    element_text 'ISSN'
  end

  # International Standard Book Number
  # @return [String] ISBN
  def isbn
    element_text 'ISBN'
  end

  # @return [Integer] PublicationItemID
  def publication_item_id
    element_integer 'PublicationItemID'
  end

  # @return [Integer] PMID
  def pmid
    element_integer 'PMID'
  end

  # @return [String] WoSItemID
  def wos_item_id
    element_text 'WoSItemID'
  end

  # ------------------------------------------------------------
  # Transition Publication ID

  # @return [Boolean] IsObsolete
  def obsolete?
    element_text('IsObsolete') =~ /true/i ? true : false
  end

  # @return [Integer] NewPublicationItemID
  def new_publication_item_id
    element_integer 'NewPublicationItemID'
  end

  # ------------------------------------------------------------
  # Publication title and abstract

  # @return [String] Title
  def title
    element_text 'Title'
  end

  # @return [String] Abstract
  def abstract
    element_text 'Abstract'
  end

  # ------------------------------------------------------------
  # Authors

  # @return [Array<String>] AuthorList.split('|')
  def authors
    author_list.split('|')
  end

  # @return [Integer] AuthorCount
  def author_count
    element_integer 'AuthorCount'
  end

  # @return [String] AuthorList
  def author_list
    element_text 'AuthorList'
  end

  # @return [Array<Hash>] an array of author names
  #                       {lastname: '', firstname: '', middlename: ''}
  def author_names
    authors.map do |name|
      ln, fn, mn = name.split(',')
      { lastname: ln, firstname: fn, middlename: mn }
    end
  end

  # ------------------------------------------------------------
  # Keywords

  # @return [Array<String>] KeywordList.split('|')
  def keywords
    keyword_list.split('|')
  end

  # @return [String] KeywordList
  def keyword_list
    element_text 'KeywordList'
  end

  # ------------------------------------------------------------
  # Publication Types and Categories

  # @return [String] DocumentCategory
  def document_category
    element_text 'DocumentCategory'
  end

  # @return [String] DocumentTypeList
  def document_type_list
    element_text 'DocumentTypeList'
  end

  # @return [Array<String>] DocumentTypeList.split('|')
  def document_types
    document_type_list.split('|')
  end

  # Is there any intersection of this publication's DocumentTypeList values
  # with the set of doc_types given?
  # @param doc_types [Array<String>] array of ScienceWire DocumentType values
  # @return [Boolean] true when DocumentTypeList contains any doc_types
  def doc_type?(doc_types)
    doc_types.to_set.intersection(document_types).any?
  end

  # @return [String] PublicationType
  def publication_type
    element_text 'PublicationType'
  end

  # @return [String] PublicationSubjectCategoryList
  def publication_subject_category_list
    element_text 'PublicationSubjectCategoryList'
  end

  # ------------------------------------------------------------
  # Publication Dates

  # @return [String] PublicationDate
  def publication_date
    element_text 'PublicationDate'
  end

  # @return [Integer] PublicationYear
  def publication_year
    element_integer 'PublicationYear'
  end

  # ------------------------------------------------------------
  # Journal or Series Information

  # A unique identifier assigned by the publisher of the journal
  # @return [String] ArticleNumber
  def article_number
    element_text 'ArticleNumber'
  end

  # @return [String] PublicationSourceTitle
  def publication_source_title
    element_text 'PublicationSourceTitle'
  end

  # Journal Volume
  # @return [String] Volume
  def volume
    element_text 'Volume'
  end

  # Journal Issue
  # @return [String] Issue
  def issue
    element_text 'Issue'
  end

  # Formatted pagination. For example: "Pagination":"166-173"
  # @return [String] Pagination
  def pagination
    element_text 'Pagination'
  end

  # ------------------------------------------------------------
  # Conference Information

  # @return [String] ConferenceTitle
  def conference_title
    element_text 'ConferenceTitle'
  end

  # @return [String] ConferenceCity
  def conference_city
    element_text 'ConferenceCity'
  end

  # @return [String] ConferenceStateCountry
  def conference_state_country
    element_text 'ConferenceStateCountry'
  end

  # @return [String] ConferenceStartDate
  def conference_start_date
    element_text 'ConferenceStartDate'
  end

  # @return [String] ConferenceEndDate
  def conference_end_date
    element_text 'ConferenceEndDate'
  end

  # ------------------------------------------------------------
  # Copyright Information

  # @return [String] Copyright publisher for journal or conference proceedings
  def copyright_publisher
    element_text 'CopyrightPublisher'
  end

  # @return [String] Copyright publisher’s city.
  def copyright_city
    element_text 'CopyrightCity'
  end

  # @return [String] Copyright Publisher’s State/Province.
  def copyright_state_province
    element_text 'CopyrightStateProvince'
  end

  # @return [String] Copyright Publisher’s Country.
  def copyright_country
    element_text 'CopyrightCountry'
  end

  # ------------------------------------------------------------
  # Bibliographic Statistics

  # @return [Integer] NumberOfReferences
  def number_of_references
    element_integer 'NumberOfReferences'
  end

  # @return [Integer] TimesCited
  def times_cited
    element_integer 'TimesCited'
  end

  # @return [Integer] TimesNotSelfCited
  def times_not_self_cited
    element_integer 'TimesNotSelfCited'
  end

  # ------------------------------------------------------------
  # Search Ranks

  # Used by ScienceWire web service to indicate the
  # normalized search result rank of the grant corresponding to
  # user provided search criteria. This is calculated as follows:
  # (Rank/(max rank in resultset) ) * 100
  # That is, the percentage of this rank when compared to the
  # best rank in the set.
  # @return [Integer] NormalizedRank
  def normalized_rank
    element_integer 'NormalizedRank'
  end

  # Used by ScienceWire web service to indicate the search
  # result ordinal rank of the grant corresponding to user
  # provided search criteria. This represents the relative order
  # of the ranks, numbered from best to worst, starting at 1.
  # @return [Integer] OrdinalRank
  def ordinal_rank
    element_integer 'OrdinalRank'
  end

  # Used by ScienceWire web service to indicate the full
  # text search result rank of the item corresponding to user
  # provided search criteria. This represents the raw similarity
  # score where higher numbers are better.
  # @return [Integer] Rank
  def rank
    element_integer 'Rank'
  end

  # ------------------------------------------------------------
  # Ruby Comparisons

  # sort by the publication_item_id
  def <=>(other)
    publication_item_id <=> other.publication_item_id
  end

  # ------------------------------------------------------------
  # Validation

  # Checks the xml_doc to verify that it is a Nokogiri::XML::Element
  # that contains a <PublicationItem> element.
  # @return [Boolean]
  def valid?
    return false unless xml_doc.is_a? Nokogiri::XML::Element
    return false unless xml_doc.name == 'PublicationItem'
    true
  end

  # ------------------------------------------------------------
  private

    def element_integer(path)
      element_text(path).to_i
    end

    def element_text(path)
      element = xml_doc.at_xpath(path)
      element.nil? ? '' : element.text
    end
end
