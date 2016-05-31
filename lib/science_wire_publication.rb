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
  # Publication Types and Categories

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
