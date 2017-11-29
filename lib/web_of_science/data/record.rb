require 'htmlentities'

module WebOfScience

  module Data

    # Utilities for working with a Web of Knowledge (WOK) record
    class Record

      # @return doc [Nokogiri::XML::Document] WOS record document
      attr_reader :doc
      attr_reader :database
      attr_reader :uid
      attr_reader :names
      attr_reader :authors
      attr_reader :doctypes
      attr_reader :identifiers
      attr_reader :doi
      attr_reader :pmid
      attr_reader :issn
      attr_reader :pub_info
      attr_reader :publishers
      attr_reader :wos_item_id
      attr_reader :titles

      # @param record [String] record in XML
      # @param encoded_record [String] record in HTML encoding
      def initialize(record: nil, encoded_record: nil, wosExtractor: WebOfScience::XmlUtil::XmlExtractor.new)
        record       = decode_record(record, encoded_record)
        @doc         = Nokogiri::XML(record) { |config| config.strict.noblanks }
        @identifiers = wosExtractor.extract_identifiers(@doc)
        @database    = wosExtractor.extract_database(@identifiers)
        @doi         = wosExtractor.extract_doi(@identifiers)
        @pmid        = wosExtractor.extract_pmid(@identifiers)
        @issn        = wosExtractor.extract_issn(@identifiers)
        @wos_item_id = wosExtractor.extract_wos_item_id(@identifiers)
        @uid         = wosExtractor.extract_uid(@doc)
        @names       = wosExtractor.extract_names(@doc)
        @authors     = wosExtractor.extract_authors(@names)
        @doctypes    = wosExtractor.extract_doctypes(@doc)
        @pub_info    = wosExtractor.extract_pub_info(@doc)
        @publishers  = wosExtractor.extract_publishers(@doc)
        @titles      = wosExtractor.extract_titles(@doc)
        @abstracts   = wosExtractor.extract_abstracts(@doc) #yes there might be multiple abstracts
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

      # @return xml [String] XML
      def to_xml
        doc.to_xml(save_with: XML_OPTIONS).strip
      end

      private

        XML_OPTIONS = Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION

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

    end

  end

end

