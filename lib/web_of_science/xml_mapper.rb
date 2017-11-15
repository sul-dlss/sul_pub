require 'htmlentities'

module WebOfScience

  # Utilities for working with a Web of Knowledge (WOK) record
  module XmlMapper

    XML_OPTIONS = Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION

    # @param element [Nokogiri::XML::Element]
    # @return attributes [Array<Array[String, String]>]
    def self.attributes_map(element)
      element.attributes.map { |name, att| [name, att.value] }
    end

    # @param element [Nokogiri::XML::Element]
    # @return fields [Hash]
    def self.attributes_with_children_hash(element)
      fields = attributes_map(element)
      fields += element.children.map { |c| [c.name, c.text] }
      fields.to_h
    end

    # Return decoded XML, whether it is passed in already or needs to be decoded
    # @param xml [String] XML
    # @param encoded_xml [String] XML with HTML encoding
    # @return [Nokogiri::XML::Document]
    # @raise RuntimeError when arguments are all nil
    def self.parse_xml(xml, encoded_xml)
      xml ||= begin
        raise 'encoded_xml is nil' if encoded_xml.nil?
        coder = HTMLEntities.new
        coder.decode(encoded_xml)
      end
      Nokogiri::XML(xml) { |config| config.strict.noblanks }
    end

  end
end
