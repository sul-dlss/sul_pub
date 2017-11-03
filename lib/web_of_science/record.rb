require 'forwardable'
require 'htmlentities'

module WebOfScience

  # Utilities for working with a Web of Knowledge (WOK) record
  class Record
    extend Forwardable

    delegate %i(database doi issn pmid uid wos_item_id) => :identifiers

    # @return doc [Nokogiri::XML::Document] WOS record document
    attr_reader :doc

    # @param record [String] record in XML
    # @param encoded_record [String] record in HTML encoding
    def initialize(record: nil, encoded_record: nil)
      record = decode_record(record, encoded_record)
      @doc = Nokogiri::XML(record) { |config| config.strict.noblanks }
    end

    # @return authors [Array<Hash<String => String>>]
    def authors
      @authors ||= names.select { |name| name['role'] == 'author' }
    end

    # @return doctypes [Array<String>]
    def doctypes
      @doctypes ||= doc.search('static_data/summary/doctypes/doctype').map(&:text)
    end

    # @return identifiers [Hash<String => String>]
    def identifiers
      @identifiers ||= WebOfScience::Identifiers.new self
    end

    # @return names [Array<Hash<String => String>>]
    def names
      @names ||= begin
        names = doc.search('static_data/summary/names/name').map do |name|
          attributes_with_children_hash(name)
        end
        names.sort { |name| name['seq_no'].to_i }
      end
    end

    # Pretty print the record in XML
    # @return nil
    def print
      require 'rexml/document'
      rexml_doc = REXML::Document.new(doc.to_xml)
      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      formatter.write(rexml_doc, $stdout)
      nil
    end

    # @return pub_info [Hash<String => String>]
    def pub_info
      @pub_info ||= begin
        info = doc.at('static_data/summary/pub_info')
        fields = attributes_map(info)
        fields += info.children.map do |child|
          [child.name, attributes_map(child).to_h ]
        end
        fields.to_h
      end
    end

    # @return publishers [Array<Hash>]
    def publishers
      @publishers ||= begin
        publishers = doc.search('static_data/summary/publishers/publisher').map do |publisher|
          # parse the publisher address(es)
          addresses = publisher.search('address_spec').map do |address|
            attributes_with_children_hash(address)
          end
          addresses.sort! { |a| a['addr_no'].to_i }
          # parse the publisher name(s)
          names = publisher.search('names/name').map do |name|
            attributes_with_children_hash(name)
          end
          # associate each publisher name with it's address by 'addr_no'
          names.each do |name|
            address = addresses.find { |addr| addr['addr_no'] == name['addr_no'] }
            name['address'] = address
          end
          names.sort { |name| name['seq_no'].to_i }
        end
        publishers.flatten
      end
    end

    # Extract the REC summary fields
    # @return summary [Hash]
    def summary
      @summary ||= {
        'doctypes' => doctypes,
        'names' => names,
        'pub_info' => pub_info,
        'publishers' => publishers,
        'titles' => titles,
      }
    end

    # An OpenStruct for the summary fields
    # @return summary [OpenStruct]
    def summary_struct
      to_o(summary)
    end

    # @return titles [Hash<String => String>]
    def titles
      @titles ||= begin
        titles = doc.search('static_data/summary/titles/title')
        titles.map { |title| [title['type'], title.text] }.to_h
      end
    end

    # Extract the REC fields
    # @return [Hash]
    def to_h
      {
        'summary' => summary,
      }
    end

    # An OpenStruct for the REC fields
    # @return [OpenStruct]
    def to_struct
      to_o(to_h)
    end

    # @return xml [String] XML
    def to_xml
      doc.to_xml(save_with: XML_OPTIONS).strip
    end

    private

      XML_OPTIONS = Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION

      # @param element [Nokogiri::XML::Element]
      # @return attributes [Array<Array[String, String]>]
      def attributes_map(element)
        element.attributes.map { |name, att| [name, att.value] }
      end

      # @param element [Nokogiri::XML::Element]
      # @return fields [Hash]
      def attributes_with_children_hash(element)
        fields = attributes_map(element)
        fields += element.children.map { |c| [c.name, c.text] }
        fields.to_h
      end

      # Return a decoded record, whether it is passed in already or needs to be decoded
      # @param record [String] record in XML
      # @param encoded_record [String] record in HTML encoding
      # @return decoded_record [String] WOS record in XML
      # @raise RuntimeError when arguments are all nil
      def decode_record(record, encoded_record)
        return record unless record.nil?
        raise 'encoded_record is nil' if encoded_record.nil?
        coder = HTMLEntities.new
        coder.decode(encoded_record)
      end

      # Convert Hash to OpenStruct with recursive application to nested hashes
      def to_o(hash)
        JSON.parse(hash.to_json, object_class: OpenStruct)
      end

  end
end
