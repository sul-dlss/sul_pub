class ScienceWirePublications
  attr_reader :xml_docs

  # @param [Nokogiri::XML] an ArrayOfPublicationItem
  def initialize(xml_docs)
    @xml_docs = xml_docs
    @reject_doc_types = Settings.sw_doc_types_to_skip
  end

  # @return [Nokogiri::XML::Element]
  def array_of_publication_item
    xml_docs.at_xpath('/ArrayOfPublicationItem')
  end

  # @return [Array<String>]
  def document_type_list
    xml_docs.xpath('//PublicationItem/DocumentTypeList').map(&:text)
  end

  # @return [Nokogiri::XML::NodeSet] a set of PublicationItem
  def publication_items
    xml_docs.xpath('//PublicationItem')
  end

  # @return [Array<Integer>] an array of PublicationItemID
  def publication_item_ids
    xml_docs.xpath('//PublicationItem/PublicationItemID').map { |item| item.text.to_i }
  end

  # Return PublicationItems that do not have any DocumentTypes in doc_types.
  # @param doc_types [Array<String>] array of ScienceWire DocumentType
  # @return [Nokogiri::XML::NodeSet] a set of PublicationItem without doc_types
  def remove_document_types(doc_types = @reject_doc_types)
    pubs = publication_items
    publication_items.each { |pub| pubs.delete(pub) if publication_has_doc_types?(pub, doc_types) }
    pubs
  end

  # Return PublicationItems that do not have any DocumentTypes in doc_types; and
  # delete PublicationItems with any DocumentType in doc_types (this modifies the xml_docs in place).
  # @param doc_types [Array<String>] array of ScienceWire DocumentType
  # @return [Nokogiri::XML::NodeSet] a set of PublicationItem without doc_types
  def remove_document_types!(doc_types = @reject_doc_types)
    xml_docs.at_xpath('/ArrayOfPublicationItem').children = remove_document_types(doc_types)
  end

  # @param doc_types [Array<String>] array of ScienceWire DocumentType
  # @return [Nokogiri::XML::NodeSet] a set of PublicationItem with doc_types
  def select_document_types(doc_types)
    publication_items.select {|pub| publication_has_doc_types?(pub, doc_types) }
  end

  private

    # Select a PublicationItem if any of it's DocumentTypeList values
    # are in the set of select_doc_types.
    # @param pub [Nokogiri::XML::Element] a PublicationItem element
    # @param doc_types [Array<String>] array of ScienceWire DocumentType
    def publication_has_doc_types?(pub, doc_types)
      pub_doc_types = pub.at_xpath('DocumentTypeList').text.split('|')
      pub_doc_types.map { |type| doc_types.include? type }.any?
    end

    # Reject a PublicationItem if any of it's DocumentTypeList values
    # are in the set of reject_doc_types.
    # @param pub [Nokogiri::XML::Element] a PublicationItem element
    # @param doc_types [Array<String>] array of ScienceWire DocumentType
    def reject_publication?(pub, reject_doc_types = @reject_doc_types)
      publication_has_doc_types?(pub, reject_doc_types)
    end
end
