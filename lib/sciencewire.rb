require 'nokogiri'
require 'citeproc'
require 'bibtex'
require 'pubmed'
require 'settings'

module Sciencewire

extend self 

include ActionView::Helpers::DateHelper

include Pubmed


@@sw_conference_proceedings_type_strings ||= Settings.sw_doc_type_mappings.conference.split(',')
@@sw_book_type_strings ||= Settings.sw_doc_type_mappings.book.split(',')

#harverst sciencewire records using author information
def harvest_author_pubs_from_sciencewire()
    #Author.find_each(:batch_size => 100) do |author|
      random = rand(Author.count - 50)
      puts "The random value for the offset: " + random.to_s
      Author.limit(5).offset(random).each do |author|
      last_name = author.pubmed_last_name
      first_name = author.pubmed_first_initial
      middle_name = author.pubmed_middle_initial
      profile_id = author.cap_profile_id
      email = author.sunetid + "@stanford.edu"

      seed_list = author.approved_publications.collect { | pub | pub.publication_identifiers.where("identifier_type = 'PublicationItemID'").first }
     
      contrib_status = 'new'
      mesh_values_for_pmids = nil
      email_list = []
      email_list << email unless email.nil?
      sw_records_doc = get_sw_guesses(last_name, first_name, middle_name, email_list, seed_list)
      sw_records_doc.xpath('//PublicationItem').each do |sw_doc|
       # ActiveRecord::Base.transaction do
          create_or_update_pub_from_sw_doc(sw_doc, contrib_status, mesh_values_for_pmids, author)
      #  end # transaction end
      end 
    end 
  end

  def create_or_update_pub_from_sw_doc(incoming_sw_xml_doc, contrib_status, mesh_values_for_pmids, author)

    pub_hash = convert_sw_publication_doc_to_hash(incoming_sw_xml_doc) 
    pmid = pub_hash[:pmid]

    existing_sw_source_record = SourceRecord.where(
      :source_name => Settings.sciencewire_source,
      :original_source_id => pub_hash[:sw_id]).first

    if existing_sw_source_record.nil? 

      mesh_for_this_pub = mesh_values_for_pmids[pmid] unless mesh_values_for_pmids.nil? 
      Publication.build_new_sciencewire_publication(pub_hash, incoming_sw_xml_doc, mesh_for_this_pub, author, contrib_status)

    elsif source_data_has_changed?(existing_sw_source_record, incoming_sw_xml_doc)
      
      existing_sw_source_record.source_data = incoming_sw_xml_doc.to_xml    
      existing_sw_source_record.publication.add_contribution(author.cap_profile_id, author.id, contrib_status)
      existing_sw_source_record.save

    end

  end

def source_data_has_changed?(existing_sw_source_record, incoming_sw_source_doc)
  existing_sw_source_record.source_data.chomp != sw_xml_doc.to_xml
end

=begin
  def add_searchable_author_names_to_db(pub_hash, publication)
    pub_hash[author].each do |author| 
            author_parts = author.split(,)
            query_hash = Hash.new
            query_hash << last_name: author_parts[0] unless author_parts[0].empty?
            query_hash << first_name: author_parts[1] unless author_parts[1].empty?
            query_hash << middle_name: author_parts[2] unless author_parts[2].empty?

            publication.searchable_author_names.where(query_hash).first_or_create()
    end
  end
=end

  

  def convert_sw_publication_doc_to_hash(publication)

    record_as_hash = Hash.new
    record_as_hash[:pmid] = publication.xpath("PMID").text unless publication.xpath("PMID").nil?
    record_as_hash[:sw_id] = publication.xpath("PublicationItemID").text
    record_as_hash[:provenance] = "sciencewire"
    record_as_hash[:title] = publication.xpath("Title").text
    record_as_hash[:abstract] = publication.xpath("Abstract").text
    record_as_hash[:author] = publication.xpath('AuthorList').text.split('|').collect{|author| {name: author}}
    record_as_hash[:year] = publication.xpath('PublicationYear').text
    record_as_hash[:keywords] = publication.xpath('KeywordList').text.split('|')
    record_as_hash[:documentTypes] = publication.xpath("DocumentTypeList").text.split('|')
    record_as_hash[:type] = lookup_sw_doc_type(record_as_hash[:documentTypes])
    # then have the default go to journal.
    record_as_hash[:documentCategory] = publication.xpath("DocumentCategory").text
    record_as_hash[:numberOfReferences] = publication.xpath("NumberOfReferences").text
    record_as_hash[:timesCited] = publication.xpath("TimesCited").text
    record_as_hash[:timesNotSelfCited] = publication.xpath("TimesNotSelfCited").text

    journal_hash = {}
    # the journal info
    journal_hash[:name] = publication.xpath('PublicationSourceTitle').text
    journal_hash[:volume] = publication.xpath('Volume').text
    journal_hash[:issue] = publication.xpath('Issue').text
    journal_hash[:pages] = publication.xpath('Pagination').text
    journal_hash[:date] = publication.xpath('PublicationDate').text
    journal_hash[:year] = publication.xpath('PublicationYear').text
    journal_hash[:publicationimpactfactor] = publication.xpath('PublicationImpactFactor').text
    journal_hash[:publicationsubjectcategories] = publication.xpath('PublicationSubjectCategoryList').text.split('|')
    
    journal_identifiers = Array.new
    journal_identifiers << {:type => 'issn', :id => publication.xpath('ISSN').text, :url => 'http://searchworks.stanford.edu/?search_field=advanced&number=' + publication.xpath('ISSN').text} unless publication.xpath('ISSN').nil?
    journal_identifiers << {:type => 'doi', :id => publication.xpath('DOI').text, :url => 'http://dx.doi.org/' + publication.xpath('DOI').text} unless publication.xpath('DOI').nil?
    journal_hash[:identifier] = journal_identifiers
    
    journal_hash[:conferencestartdate] = publication.xpath('ConferenceStartDate').text
    journal_hash[:conferenceenddate] = publication.xpath('ConferenceEndDate').text

    record_as_hash[:journal] = journal_hash

    record_as_hash[:rank] =  publication.xpath('Rank').text
    record_as_hash[:ordinalRank] = publication.xpath('OrdinalRank').text
    record_as_hash[:normalizedRank] = publication.xpath('NormalizedRank').text
    record_as_hash[:newPublicationId] = publication.xpath('NewPublicationItemID').text
    record_as_hash[:isObsolete] = publication.xpath('IsObsolete').text
    record_as_hash[:copyrightPublisher] =  publication.xpath('CopyrightPublisher').text
    record_as_hash[:copyrightCity] = publication.xpath('CopyrightCity').text

    article_identifiers = Array.new
    article_identifiers << {:type =>'PMID', :id => publication.at_xpath("PMID").text, :url => 'http://www.ncbi.nlm.nih.gov/pubmed/' + publication.xpath("PMID").text } unless publication.at_xpath("PMID").nil?
    article_identifiers << {:type => 'WoSItemID', :id => publication.at_xpath("WoSItemID").text, :url => 'http://ws.isiknowledge.com/cps/openurl/service?url_ver=Z39.88-2004&rft_id=info:ut/' + publication.xpath("WoSItemID").text} unless publication.at_xpath("WoSItemID").nil?
    article_identifiers << {:type => 'PublicationItemID', :id => publication.at_xpath("PublicationItemID").text} unless publication.at_xpath("PublicationItemID").nil?
    record_as_hash[:identifier] = article_identifiers

    #puts "the record as hash"
    #puts record_as_hash.to_s
    record_as_hash
  end

    

def lookup_sw_doc_type(doc_type_list)
    
    if !(@@sw_conference_proceedings_type_strings & doc_type_list).empty?
      type =  Settings.sul_doc_types.inproceedings
    elsif !(@@sw_book_type_strings & doc_type_list).empty?
      type =  Settings.sul_doc_types.book
    else
      type =  Settings.sul_doc_types.article
    end
    type
end

def query_sciencewire_for_publication(first_name, last_name, middle_name, title, year)
  result = []
  xml_query = '<![CDATA[
     <query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/
    XMLSchema">
      <Criterion ConjunctionOperator="AND">
        <Criteria>'

unless last_name.blank?
  xml_query << '<Criterion>
            <Filter>
              <Column>AuthorLastName</Column>
              <Operator>BeginsWith</Operator>
              <Value>' + last_name + '</Value>
            </Filter>
          </Criterion>' 
end
unless first_name.blank?
  xml_query << '<Criterion>
            <Filter>
              <Column>AuthorFirstName</Column>
              <Operator>BeginsWith</Operator>
              <Value>' + first_name + '</Value>
            </Filter>
          </Criterion>' 
end
unless title.blank?
  xml_query << '<Criterion>
            <Filter>
              <Column>Title</Column>
              <Operator>Contains</Operator>
              <Value>' + title + '</Value>
            </Filter>
          </Criterion>' 
end
unless year.blank?
  xml_query << '<Criterion>
            <Filter>
              <Column>PublicationYear</Column> 
              <Operator>Equals</Operator> 
              <Value>' + year.to_s + '</Value>
            </Filter>
          </Criterion>' 
end
   xml_query << '</Criteria>
      </Criterion>
      <Columns>
        <SortColumn>
          <Column>Rank</Column>
          <Direction>Descending</Direction>
        </SortColumn>
      </Columns>
     <MaximumRows>' + Settings.sciencewire_harvest_max.to_s + '</MaximumRows>
    </query>
    ]]>'
    xml_results = query_sciencewire(xml_query)

    xml_results.xpath('//PublicationItem').each do |sw_xml_doc|
     # puts sw_xml_doc.to_xml
    # result << generate_json_for_pub(convert_sw_publication_doc_to_hash(sw_xml_doc))    
    result << convert_sw_publication_doc_to_hash(sw_xml_doc)   
  end 
  result
end

def pull_records_from_sciencewire_for_pmids(pmid_list)
  pmidValuesAsXML = pmid_list.collect { |pmid| "&lt;Value&gt;#{pmid}&lt;/Value&gt;"}.join
  xml_query = '&lt;query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"&gt;
            &lt;Criterion ConjunctionOperator="AND"&gt;
              &lt;Criteria&gt;
                &lt;Criterion&gt;
                  &lt;Filter&gt;
                    &lt;Column&gt;PMID&lt;/Column&gt;
                    &lt;Operator&gt;In&lt;/Operator&gt;
                    &lt;Values&gt;' +
      pmidValuesAsXML +
    '&lt;/Values&gt;
                  &lt;/Filter&gt;
                &lt;/Criterion&gt;
              &lt;/Criteria&gt;
            &lt;/Criterion&gt;
            &lt;Columns&gt;
              &lt;SortColumn&gt;
                &lt;Column&gt;Rank&lt;/Column&gt;
                &lt;Direction&gt;Descending&lt;/Direction&gt;
              &lt;/SortColumn&gt;
            &lt;/Columns&gt;
            &lt;MaximumRows&gt;500&lt;/MaximumRows&gt;
          &lt;/query&gt;'
      query_sciencewire(xml_query)
end

def query_sciencewire(xml_query)

  wrapped_xml_query = '<?xml version="1.0"?>
          <ScienceWireQueryXMLParameter xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
            <xmlQuery>' + xml_query + '</xmlQuery>
          </ScienceWireQueryXMLParameter>'

    #start_time = Time.now
    http = Net::HTTP.new("sciencewirerest.discoverylogic.com", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.ssl_version = :SSLv3
    request = Net::HTTP::Post.new("/PublicationCatalog/PublicationQuery?format=xml")
    request["LicenseID"] = "***REMOVED***"
    request["Host"] = "sciencewirerest.discoverylogic.com"
    request["Connection"] = "Keep-Alive"
    request["Expect"] = "100-continue"
    request["Content-Type"] = "text/xml"
    

    request.body = wrapped_xml_query
    response = http.request(request)
    #puts "ScienceWire pubmed conversion call took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
    #start_time = Time.now
    xml_doc = Nokogiri::XML(response.body)
    #puts xml_doc.to_xml
    queryId = xml_doc.xpath('//queryID').text

    fullPubsRequest = Net::HTTP::Get.new("/PublicationCatalog/PublicationQuery/" + queryId + "?format=xml&v=version/3&page=0&pageSize=2147483647")
    fullPubsRequest["Content_Type"] = "text/xml"
    fullPubsRequest["LicenseID"] = "***REMOVED***"
    fullPubsRequest["Host"] = "sciencewirerest.discoverylogic.com"
    fullPubsRequest["Connection"] = "Keep-Alive"

    fullPubResponse = http.request(fullPubsRequest)
    #puts "ScienceWire full record retrieval call took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
    #start_time = Time.now
    Nokogiri::XML(fullPubResponse.body)
    #puts "Parsing ScienceWire results took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)

  end

  


  def get_sw_guesses(last_name, first_name, middle_name, email_list, seed_list)


    http = Net::HTTP.new("sciencewirerest.discoverylogic.com", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.ssl_version = :SSLv3
    request = Net::HTTP::Post.new("/PublicationCatalog/MatchedPublicationItemIdsForAuthor?format=xml")
    request["LicenseID"] = "***REMOVED***"
    request["Host"] = "sciencewirerest.discoverylogic.com"
    request["Connection"] = "Keep-Alive"
    request["Expect"] = "100-continue"
    request["Content-Type"] = "text/xml"

    bod = '<?xml version="1.0"?>
<PublicationAuthorMatchParameters xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <Authors>
    <Author>
      <LastName>' + last_name + '</LastName>
      <FirstName>' + first_name + '</FirstName>
      <MiddleName>' + middle_name + '</MiddleName>
      <City>Stanford</City>
      <State>CA</State>
      <Country>USA</Country>
    </Author>
  </Authors>
  <DocumentCategory>Journal Document</DocumentCategory>' 

    unless seed_list.blank?
      bod << '<PublicationItemIds>'
      bod << seed_list.collect { |pubId| "<int>#{pubId}</int>"}.join
      bod << '</PublicationItemIds>'
    end

    unless email_list.blank?
      bod << '<Emails>'
      bod <<   email_list.collect { |email| "<string>#{email}</string>"}.join
      bod << '</Emails>'
    end

    bod << '<LimitToHighQualityMatchesOnly>false</LimitToHighQualityMatchesOnly>'
    bod << '</PublicationAuthorMatchParameters>'

    request.body = bod
    response = http.request(request)
    xml_doc = Nokogiri::XML(response.body)
    #puts xml_doc.to_xml
    items = xml_doc.xpath('/ArrayOfItemMatchResult/ItemMatchResult/PublicationItemID').collect { |itemId| itemId.text}.join(',')
    #puts "sciencewire guesses at pub ids for given author: " + items.to_s
    fullPubsRequest = Net::HTTP::Get.new("/PublicationCatalog/PublicationItems?format=xml&publicationItemIDs=" + items)
    fullPubsRequest["Content-Type"] = "text/xml"
    fullPubsRequest["LicenseID"] = "***REMOVED***"
    fullPubsRequest["Host"] = "sciencewirerest.discoverylogic.com"
    fullPubsRequest["Connection"] = "Keep-Alive"

    fullPubResponse = http.request(fullPubsRequest).body
  #puts fullPubResponse.to_s
    Nokogiri::XML(fullPubResponse)

    # puts xml_result
    # puts "Time to run sw query in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)


  end


  

end  #module end

# puts "the seed list: " + seed_list.to_s
     # authors_sw_pubs = author.publications(:include => :publication_identifers, :conditions => "publication_identifiers.identifier_type = 'PublicationItemID'")
      #authors_sw_pubs.each do | pub |
       # seed_list = pub.publication_identifiers.where("identifier_type = 'PublicationItemID'").collect { |ident|  ident.identifier_value  }
      #end
      #seed_list = [5750109]
      # puts "seed_list = " + seed_list.to_s
=begin

  "author": [
       {
           "name": "Carberry, Josiah",
           "alternate": [
               "Josiah Carberry"
           ],
           "firstname": "Josiah",
           "lastname": "Carberry",
           "middlename": "Stinkney",
           "identifier": [
               {
                   "id": "0003",
                   "type": "cap",
                   "uri": "http://cap.stanford.edu/0003"
               },
               {
                   "id": "stinkney",
                   "type": "sunet"
               },
               {
                   "id": "0000-0002-1825-0097",
                   "type": "orcid",
                   "url": "http: //orcid.org/0000-0002-1825-0097"
               },
               {
                   "id": "7007156898",
                   "type": "scopus",
                   "url": "http: //www.scopus.com/authid/detail.url?authorId=7007156898"
               },
               {
                   "id": "Josiah_Carberry",
                   "type": "wikipedia",
                   "url": "http: //en.wikipedia.org/wiki/Josiah_Carberry"
               }
           ]
       }
       ...other authors
       ]
=end
