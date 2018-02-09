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
    def publishers
      WebOfScience::MapPublisher.new(self).publishers
    end

    # Map WOS record data into the SUL PubHash data
    # @return [Hash]
    def pub_hash
      @pub_hash ||= WebOfScience::MapPubHash.new(self).pub_hash
    end

    # Find a WebOfScienceSourceRecord
    # @return [WebOfScienceSourceRecord, nil]
    def source_record
      WebOfScienceSourceRecord.find_by(uid: uid)
    end

    # Attributes for a new WebOfScienceSourceRecord
    # @return [Hash]
    def source_record_attr
      attr = {
        source_data: to_xml,
        identifiers: identifiers.to_h
      }
      attr[:doi] = doi if doi.present?
      attr[:pmid] = pmid if pmid.present?
      attr
    end

    # Create a WebOfScienceSourceRecord from #source_record_attr
    # @return [WebOfScienceSourceRecord]
    def source_record_find_or_create
      source_record || WebOfScienceSourceRecord.create!(source_record_attr)
    end

    # Update a WebOfScienceSourceRecord, if it exists and source fingerprints differ
    # @return [Boolean]
    def source_record_update
      src = source_record
      return false if src.nil?
      new_attr = source_record_attr
      new_src = WebOfScienceSourceRecord.new(new_attr)
      return false if new_src.source_fingerprint == src.source_fingerprint
      src.update(new_attr)
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

    # @return [Hash<String => String>]
    def titles
      @titles ||= begin
        titles = doc.search('static_data/summary/titles/title')
        titles.map { |title| [title['type'], title.text] }.to_h
      end
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
