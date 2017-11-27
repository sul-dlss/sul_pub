require 'forwardable'

module WebOfScience

  # Utilities for working with a Web of Knowledge (WOK) record
  class Record
    extend Forwardable

    delegate %i(abstracts) => :abstract_mapper

    delegate %i(database doi eissn issn pmid uid wos_item_id) => :identifiers
    delegate logger: :WebOfScience

    delegate %i(publishers) => :publisher

    # @!attribute [r] doc
    #   @return [Nokogiri::XML::Document] WOS record document
    attr_reader :doc

    # @param record [String] record in XML
    # @param encoded_record [String] record in HTML encoding
    def initialize(record: nil, encoded_record: nil)
      @doc = WebOfScience::XmlParser.parse(record, encoded_record)
    end

    # @return [WebOfScience::MapAbstract]
    def abstract_mapper
      @abstract_mapper ||= WebOfScience::MapAbstract.new(self)
    end

    # @return [Array<Hash<String => String>>]
    def authors
      @authors ||= names.select { |name| name['role'] == 'author' }
    end

    # @return [Array<String>]
    def doctypes
      @doctypes ||= doc.search('static_data/summary/doctypes/doctype').map(&:text)
    end

    # @return [Hash<String => String>]
    def identifiers
      @identifiers ||= WebOfScience::Identifiers.new self
    end

    # @return [Array<Hash<String => String>>]
    def names
      @names ||= begin
        names = doc.search('static_data/summary/names/name').map do |name|
          WebOfScience::XmlParser.attributes_with_children_hash(name)
        end
        names.sort { |name| name['seq_no'].to_i }
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
    def publisher
      @publisher ||= WebOfScience::MapPublisher.new(self)
    end

    # Extract the REC summary fields
    # @return [Hash<String => Object>]
    def summary
      @summary ||= {
        'abstracts' => abstracts,
        'doctypes' => doctypes,
        'names' => names,
        'pub_info' => pub_info,
        'publishers' => publishers,
        'titles' => titles,
      }
    end

    # An OpenStruct for the summary fields
    # @return [OpenStruct]
    def summary_struct
      to_o(summary)
    end

    # @return [Hash<String => String>]
    def titles
      @titles ||= begin
        titles = doc.search('static_data/summary/titles/title')
        titles.map { |title| [title['type'], title.text] }.to_h
      end
    end

    # Extract the REC fields
    # @return [Hash<String => Object>]
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

    # @return [String] XML
    def to_xml
      doc.to_xml(save_with: WebOfScience::XmlParser::XML_OPTIONS).strip
    end

    private

      # Convert Hash to OpenStruct with recursive application to nested hashes
      def to_o(hash)
        JSON.parse(hash.to_json, object_class: OpenStruct)
      end
  end
end
