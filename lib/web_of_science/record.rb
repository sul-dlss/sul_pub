# frozen_string_literal: true

require 'forwardable'

module WebOfScience
  # Utilities for working with a Web of Knowledge (WOK) record
  class Record
    extend Forwardable

    XML_OPTIONS = Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION

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
      Rails.logger.debug("\n")
      nil
    end

    # @return [Hash<String => [String, Hash<String => String>]>]
    def pub_info
      @pub_info ||= begin
        info = doc.at('static_data/summary/pub_info')
        fields = WebOfScience::XmlParser.attributes_map(info)
        fields += info.children.map do |child|
          [child.name, WebOfScience::XmlParser.attributes_map(child).to_h]
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
        titles.to_h { |title| [title['type'], title.text] }
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
        'titles' => titles
      }
    end

    # @return [String] XML
    def to_xml
      doc.to_xml(save_with: XML_OPTIONS).strip
    end

    # @return [WebOfScienceSourceRecord] pre-extracted and persisted ActiveRecord instance
    def find_or_create_model
      WebOfScienceSourceRecord.find_or_create_by(uid:) do |rec|
        rec.record = self
        rec.database = database
      end
    end

    # Does record have an associated publication? (based on matching PublicationIdentifiers)
    # Note: must use unique identifiers, don't use ISSN or similar series level identifiers
    # We search for all PubIDs at once instead of serial queries.  No need to hit the same table multiple times.
    # @return [::Publication, nil] a matched or newly minted publication
    def matching_publication
      Publication.joins(:publication_identifiers).where(
        "publication_identifiers.identifier_value IS NOT NULL AND (
         (publication_identifiers.identifier_type = 'WosUID' AND publication_identifiers.identifier_value = ?) OR
         (publication_identifiers.identifier_type = 'WosItemID' AND publication_identifiers.identifier_value = ?) OR
         (publication_identifiers.identifier_type = 'doi' AND publication_identifiers.identifier_value = ?) OR
         (publication_identifiers.identifier_type = 'pmid' AND publication_identifiers.identifier_value = ?))",
        uid, wos_item_id, doi, pmid
      ).order(
        Arel.sql("CASE
          WHEN publication_identifiers.identifier_type = 'WosUID' THEN 0
          WHEN publication_identifiers.identifier_type = 'WosItemID' THEN 1
          WHEN publication_identifiers.identifier_type = 'doi' THEN 2
          WHEN publication_identifiers.identifier_type = 'pmid' THEN 3
         END")
      ).first
    end
  end
end
