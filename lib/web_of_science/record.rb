require 'forwardable'

module WebOfScience

  # Utilities for working with a Web of Knowledge (WOK) record
  class Record
    extend Forwardable

    delegate %i(database doi eissn issn pmid uid wos_item_id) => :identifiers

    # @return doc [Nokogiri::XML::Document] WOS record document
    attr_reader :doc

    # @param record [String] record in XML
    # @param encoded_record [String] record in HTML encoding
    def initialize(record: nil, encoded_record: nil)
      @doc = WebOfScience::XmlParser.parse(record, encoded_record)
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
          WebOfScience::XmlParser.attributes_with_children_hash(name)
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
      $stdout.write("\n")
      nil
    end

    # @return pub_info [Hash<String => String>]
    def pub_info
      @pub_info ||= begin
        info = doc.at('static_data/summary/pub_info')
        fields = WebOfScience::XmlParser.attributes_map(info)
        fields += info.children.map do |child|
          [child.name, WebOfScience::XmlParser.attributes_map(child).to_h ]
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
            WebOfScience::XmlParser.attributes_with_children_hash(address)
          end
          addresses.sort! { |a| a['addr_no'].to_i }
          # parse the publisher name(s)
          names = publisher.search('names/name').map do |name|
            WebOfScience::XmlParser.attributes_with_children_hash(name)
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

    # Map WOS record data into the SUL PubHash data
    # @return [Hash]
    def pub_hash
      @pub_hash ||= WebOfScience::MapPubHash.new(self).pub_hash
    end

    # An OpenStruct for the REC fields
    # @return [OpenStruct]
    def to_struct
      to_o(to_h)
    end

    # @return xml [String] XML
    def to_xml
      doc.to_xml(save_with: WebOfScience::XmlParser::XML_OPTIONS).strip
    end

    private

      # Convert Hash to OpenStruct with recursive application to nested hashes
      def to_o(hash)
        JSON.parse(hash.to_json, object_class: OpenStruct)
      end

      def logger
        @logger ||= NotificationManager.wos_logger
      end

  end
end
