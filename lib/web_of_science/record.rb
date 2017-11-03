require 'htmlentities'

module WebOfScience

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
    def initialize(record: nil, encoded_record: nil, wosExtractor: WebOfScience::WosExtractor.new)
      record       = decode_record(record, encoded_record)
      @doc         = Nokogiri::XML(record) { |config| config.strict.noblanks }
      @uid         = wosExtractor.extract_uid(@doc)
      @database    = wosExtractor.extract_database(@uid)
      @names       = wosExtractor.extract_names(@doc)
      @authors     = wosExtractor.extract_authors(@names)
      @doctypes    = wosExtractor.extract_doctypes(@doc)
      @identifiers = wosExtractor.extract_identifiers(@doc)
      @doi         = wosExtractor.extract_doi(@identifiers)
      @pmid        = wosExtractor.extract_pmid(@identifiers)
      @issn        = wosExtractor.extract_issn(@identifiers)
      @pub_info    = wosExtractor.extract_pub_info(@doc)
      @publishers  = wosExtractor.extract_publishers(@doc)
      @wos_item_id = wosExtractor.extract_wos_item_id(@uid)
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


    def toPubHash
      record_as_hash = {}
      ids            = []

      ids   << { type: 'PMID', id: @pmid, url: "#{Settings.PUBMED.ARTICLE_BASE_URI}#{@pmid}" } unless @pmid.blank?
      ids   << { type: 'WoSItemID', id: @wos_item_id, url: "#{Settings.SCIENCEWIRE.ARTICLE_BASE_URI}#{@wos_item_id}" } unless @wos_item_id.blank?
      ids   << { type: 'doi', id: @doi, url: "#{Settings.DOI.BASE_URI}#{@doi}" } unless @doi.blank?
      ids   << { type: 'issn', id: @issn, url: Settings.SULPUB_ID.SEARCHWORKS_URI + @issn } unless (@issn == nil)


      record_as_hash[:provenance] = Settings.sciencewire_source
      record_as_hash[:pmid]       = @pmid unless @pmid.blank?
      record_as_hash[:issn]       = @identifiers['issn']  unless (@identifiers['issn'] == nil)
      record_as_hash[:identifier] = ids


      record_as_hash[:title]                = @titles['item']
      record_as_hash[:abstract_restricted]  = @abstracts #yes there might be multiple abstracts
      record_as_hash[:author]               = @authors.map{|e|  { name: e['display_name']}}


      record_as_hash[:year] = @pub_info['pubyear']
      record_as_hash[:date] = @pub_info['sortdate']

      record_as_hash[:authorcount] = @authors.count

      record_as_hash[:documenttypes_sw] = @doctypes

      #record_as_hash[:documentcategory_sw] = publication.xpath('DocumentCategory').text unless publication.xpath('DocumentCategory').blank?
      #sul_document_type = lookup_cap_doc_type_by_sw_doc_category(record_as_hash[:documentcategory_sw])
      #record_as_hash[:type] = sul_document_type

      record_as_hash[:publisher] = publishers.map{|e| e['display_name']}
      record_as_hash[:city] = publishers.map{|e| e['address']['city']} ## Something is not right with the addresses field, need to be double checked
      #record_as_hash[:stateprovince] = publication.xpath('CopyrightStateProvince').text unless publication.xpath('CopyrightStateProvince').blank?
      #record_as_hash[:country] = publication.xpath('CopyrightCountry').text unless publication.xpath('CopyrightCountry').blank?
      record_as_hash[:pages] = @pub_info['page']['begin'] + '-' + @pub_info['page']['end']

      record_as_hash

      PubHash.new(record_as_hash)
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
