require 'forwardable'
require 'htmlentities'

module WebOfScience

  # Utilities for working with Web of Science records
  class Records
    extend Forwardable
    include Enumerable

    # @return [Integer] WOS record count
    def_delegators :rec_nodes, :count

    # @return [Boolean] WOS records empty?
    def_delegators :rec_nodes, :empty?

    # @return [WebOfScience::Record]
    def_delegators :to_a, :sample

    # @return xml [String] WOS records in XML
    def_delegators :doc, :to_xml

    # @return doc [Nokogiri::XML::Document] WOS records document
    attr_reader :doc

    # @param records [String] records in XML
    # @param encoded_records [String] records in HTML encoding
    def initialize(records: nil, encoded_records: nil)
      @records = records
      @encoded_records = encoded_records
      @records = decode_records if records.nil? && !encoded_records.nil?
      @doc = Nokogiri::XML(@records) { |config| config.strict.noblanks }
    end

    # Group records by the database prefix in the UID
    #  - where a database prefix is missing, groups records into 'MISSING_DB'
    # @return [Hash<String => WebOfScience::Records>]
    def by_database
      db_recs = rec_nodes.group_by do |rec|
        uid_split = record_uid(rec).split(':')
        uid_split.length > 1 ? uid_split[0] : 'MISSING_DB'
      end
      db_recs.each_key do |db|
        rec_doc = Nokogiri::XML("<records>#{db_recs[db].map(&:to_xml).join}</records>")
        db_recs[db] = WebOfScience::Records.new(records: rec_doc.to_xml)
      end
      db_recs
    end

    # Iterate over WebOfScience::WokRecord objects
    # @yield wos_record [WebOfScience::Record]
    def each
      rec_nodes.each { |rec| yield WebOfScience::Record.new(record: rec.to_xml) }
    end

    # @return uids [Array<String>] the rec_nodes UID values (in order)
    def uids
      uid_nodes.map(&:text)
    end

    # @return uid_nodes [Nokogiri::XML::NodeSet] the rec_nodes UID nodes
    def uid_nodes
      rec_nodes.search('UID')
    end

    # Find duplicate WoS UID values
    # @param record_setB [WebOfScience::Records]
    # @return [Array] duplicate WoS UID values
    def duplicate_uids(record_setB)
      uids & record_setB.uids
    end

    # Find duplicate WoS records
    # @param record_setB [WebOfScience::Records]
    # @return [Nokogiri::XML::NodeSet] duplicate records
    def duplicate_records(record_setB)
      duplicates = []
      uid_intersection = duplicate_uids(record_setB)
      unless uid_intersection.empty?
        # create a new set of records, use a philosophy of immutability
        # Nokogiri::XML::NodeSet enumerable methods do not return new objects
        # Nokogiri::XML::Document.dup is a deep copy
        docB = record_setB.doc.dup # do not chain Nokogiri methods
        duplicates = docB.search('REC').select { |rec| uid_intersection.include? record_uid(rec) }
      end
      Nokogiri::XML::NodeSet.new(Nokogiri::XML::Document.new, duplicates)
    end

    # Find new WoS records, rejecting duplicates
    # @param record_setB [WebOfScience::Records]
    # @return [Nokogiri::XML::NodeSet] additional new records
    def new_records(record_setB)
      # create a new set of records, use a philosophy of immutability
      # Nokogiri::XML::NodeSet enumerable methods do not return new objects
      # Nokogiri::XML::Document.dup is a deep copy
      docB = record_setB.doc.dup # do not chain Nokogiri methods
      new_rec = docB.search('REC')
      # reject duplicate records
      uid_dups = duplicate_uids(record_setB)
      new_rec = new_rec.reject { |rec| uid_dups.include? record_uid(rec) } unless uid_dups.empty?
      Nokogiri::XML::NodeSet.new(Nokogiri::XML::Document.new, new_rec)
    end

    # Merge WoS records
    # @param record_setB [WebOfScience::Records]
    # @return records [WebOfScience::Records] merged set of records
    def merge_records(record_setB)
      # create a new set of records, use a philosophy of immutability
      # Nokogiri::XML::Document.dup is a deep copy
      docA = doc.dup # do not chain Nokogiri methods
      # merge new records and return a new WebOfScience::Records instance
      docA.at('records').add_child(new_records(record_setB))
      WebOfScience::Records.new(records: docA.to_xml)
    end

    # Pretty print the records in XML
    # @return nil
    def print
      require 'rexml/document'
      rexml_doc = REXML::Document.new(doc.to_xml)
      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      formatter.write(rexml_doc, $stdout)
      nil
    end

    # Extract all the 'REC' nodes
    # @return [Nokogiri::XML::NodeSet]
    def rec_nodes
      doc.search('REC')
    end

    private

      attr_reader :records
      attr_reader :encoded_records

      # The UID for a WoS REC
      # @param rec [Nokogiri::XML::Element] a Wos 'REC' element
      # @return UID [String] a Wos 'UID' value
      def record_uid(rec)
        rec.search('UID').text
      end

      # @return decoded_records [String] WOS records in XML
      def decode_records
        coder = HTMLEntities.new
        coder.decode(encoded_records)
      end

  end
end
