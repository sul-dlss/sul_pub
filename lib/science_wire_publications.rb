class ScienceWirePublications
  include Enumerable

  attr_reader :xml_doc
  attr_accessor :remove_document_types

  # @return [Integer] a count of //PublicationItem
  delegate :count, to: :publication_items

  # @param [Nokogiri::XML] an ArrayOfPublicationItem
  # @param remove_document_types [Array<String>] DocumentTypes to skip
  def initialize(xml_doc, remove_document_types = Settings.sw_doc_types_to_skip)
    @xml_doc = xml_doc
    @remove_document_types = remove_document_types
  end

  # @return [Nokogiri::XML::Element]
  def array_of_publication_item
    xml_doc.xpath('//ArrayOfPublicationItem').first
  end

  def each
    publication_items.each {|pub| yield pub }
  end

  # Apply configured filter to remove any PublicationItem that contains a
  # DocumentType in the list of remove_document_types.
  # @return [Array<ScienceWirePublication>] selected ScienceWirePublication
  def filter_publication_items
    pubs = publication_items.dup
    pubs.delete_if {|pub| pub.doc_type?(remove_document_types) } unless remove_document_types.blank?
    pubs
  end

  # @return [Array<ScienceWirePublication>] an array of ScienceWirePublication
  def publication_items
    pub_nodes = array_of_publication_item.xpath('PublicationItem')
    pub_nodes.map {|item| ScienceWirePublication.new(item) }
  end

  # Checks the xml_doc to verify that it is a Nokogiri::XML::Document
  # that contains an <ArrayOfPublicationItem> element.
  # @return [Boolean]
  def valid?
    return false unless xml_doc.is_a? Nokogiri::XML::Document
    return false if array_of_publication_item.nil?
    true
  end
end
