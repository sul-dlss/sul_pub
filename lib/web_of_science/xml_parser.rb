require 'htmlentities'

module WebOfScience
  # Utilities for working with a Web of Knowledge (WOK) record
  module XmlParser

    XML_OPTIONS = Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION

    # @param element [Nokogiri::XML::Element]
    # @return [Array<Array[String]>] Pairs of strings, attribute name and value, suitable for .to_h
    def self.attributes_map(element)
      element.attributes.map { |name, att| [name, att.value] }
    end

    # @param element [Nokogiri::XML::Element]
    # @return [Hash<String => String>]
    def self.attributes_with_children_hash(element)
      (attributes_map(element) + element.children.map { |c| [c.name, c.text] }).to_h
    end

    # Return decoded XML, whether it is passed in already or needs to be decoded
    # @param xml [String, nil] XML with regular encoding
    # @param encoded_xml [String, nil] XML with HTML encoding, ignored if first param is present
    # @return [Nokogiri::XML::Document]
    # @raise RuntimeError when arguments are all nil
    def self.parse(xml, encoded_xml)
      xml ||= begin
        raise 'encoded_xml is nil' if encoded_xml.nil?
        HTMLEntities.new.decode(encoded_xml)
      end
      Nokogiri::XML(xml) { |config| config.strict.noblanks }
    end
  end
end
