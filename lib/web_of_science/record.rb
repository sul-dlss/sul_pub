require 'forwardable'

module WebOfScience

  # Utilities for working with a Web of Knowledge (WOK) record
  class Record
    extend Forwardable

    delegate %i[database doi eissn issn pmid uid wos_item_id] => :identifiers
    delegate logger: :WebOfScience

    # @!attribute [r] doc
    #   @return [Nokogiri::XML::Document] WOS record document
    attr_reader :doc

    # @param record [String] record in XML
    # @param encoded_record [String] record in HTML encoding
    def initialize(record: nil, encoded_record: nil)
      @doc = WebOfScience::XmlParser.parse(record, encoded_record)
    end

    # @return [Array<String>]
    def abstracts
      WebOfScience::MapAbstract.new(self).abstracts
    end

    # @return [Array<Hash<String => String>>]
    def authors
      names.select { |name| name['role'] == 'author' }
    end

    # @return [Array<Hash<String => String>>]
    def editors
      names.select { |name| name['role'] == 'book_editor' }
    end

    # @return [Array<String>]
    def doctypes
      doc.search('static_data/summary/doctypes/doctype').map(&:text)
    end

    # @return [Hash<String => String>]
    def identifiers
      @identifiers ||= WebOfScience::Identifiers.new(self)
    end

    # @return [Array<Hash<String => String>>]
    def names
      @names ||= begin
        name_elements = doc.search('static_data/summary/names/name').map do |n|
          WebOfScience::XmlParser.attributes_with_children_hash(n)
        end
        name_elements.sort_by { |name| name['seq_no'].to_i }
      end
    end

    # Pretty print the record in XML
    # @return [nil]
    def print
      require 'rexml/document'
      rexml_doc = REXML::Document.new(doc.to_xml)
      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      formatter.write(rexml_doc, $stdout)
      $stdout.write("\n")
      nil
    end

    # @return [Hash<String => String>]
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

    # @return [WebOfScience::MapPublisher]
    def publishers
      WebOfScience::MapPublisher.new(self).publishers
    end

    # @return [Hash<String => String>]
    def titles
      @titles ||= begin
        titles = doc.search('static_data/summary/titles/title')
        titles.map { |title| [title['type'], title.text] }.to_h
      end
    end

    # Map WOS record data into the SUL PubHash data
    # @return [Hash]
    def pub_hash
      @pub_hash ||= WebOfScience::MapPubHash.new(self).pub_hash
    end

    # Extract the REC fields
    # @return [Hash<String => Object>]
    def to_h
      {
        'abstracts' => abstracts,
        'doctypes' => doctypes,
        'names' => names,
        'pub_info' => pub_info,
        'publishers' => publishers,
        'titles' => titles,
      }
    end

    # An OpenStruct for the REC fields
    # @return [OpenStruct]
    def to_struct
      # Convert Hash to OpenStruct with recursive application to nested hashes
      JSON.parse(to_h.to_json, object_class: OpenStruct)
    end

    # @return [String] XML
    def to_xml
      doc.to_xml(save_with: WebOfScience::XmlParser::XML_OPTIONS).strip
    end

  end
end
