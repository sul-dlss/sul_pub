require 'nokogiri'
require 'citeproc'
require 'bibtex'
require 'debugger'

module SulPub

  include ActionView::Helpers::DateHelper

#ingest sciencewire records for cap pmid list and generate authors and contributions
def create_new_pubs_and_contributions_for_pmids(pmids, contribs)
    mesh_values_for_pmids = get_mesh_from_pubmed(pmids)
    sw_records_doc = pull_records_from_sciencewire_for_pmids(pmids)
    sw_records_doc.xpath('//PublicationItem').each do |sw_record_doc|
      pmid = sw_record_doc.xpath("PMID").text
      #ActiveRecord::Base.transaction do
        begin
          contribution = contribs[pmid]
          author = get_cap_author(contribution['faculty_id'])
          create_or_update_pub_from_sw_doc(sw_record_doc, contribution['status'], mesh_values_for_pmids, author)
        rescue Exception => e  
          puts e.message  
          puts e.backtrace.inspect  
          puts "the offending pmid: " + pmid.to_s
          puts "the contrib: " + contribution.to_s
          puts "the author: " + author.to_s

        end
     # end
    end
  end

#harverst sciencewire records using author information
def harvest_author_pubs_from_sciencewire()
    Author.find_each(:batch_size => 10) do |author|
      
      last_name = author.pubmed_last_name
      first_name = author.pubmed_first_initial
      middle_name = author.pubmed_middle_initial
      profile_id = author.cap_profile_id
      email = author.sunetid + "@stanford.edu"

      seed_list = Array.new
      authors_sw_pubs = author.publications(:include => :publication_identifers, :conditions => "publication_identifiers.identifier_type = 'PublicationItemID'")
      authors_sw_pubs.each do | pub |
        seed_list = pub.publication_identifiers.where("identifier_type = 'PublicationItemID'").collect { |ident|  ident.identifier_value  }
      end
      #seed_list = [5750109]
      # puts "seed_list = " + seed_list.to_s
      email_list = []
      email_list << email unless email.nil?
      sw_records_doc = get_sw_guesses(last_name, first_name, middle_name, email_list, seed_list)
      sw_records_doc.xpath('//PublicationItem').each do |sw_doc|
       # ActiveRecord::Base.transaction do
          create_or_update_pub_from_sw_doc(sw_doc, 'new', nil, author)
      #  end # transaction end
      end 
    end 
  end



  def create_or_update_pub_from_sw_doc(sw_xml_doc, contrib_status, mesh_values_for_pmids, author)

    pub_hash = convert_sw_publication_doc_to_hash(sw_xml_doc)
    
    pmid = pub_hash[:pmid]
    sw_pub_id = pub_hash[:sw_id]
    title = pub_hash[:title]
    year = pub_hash[:publicationYear]

    save_source_record(sw_xml_doc.to_xml, "sw", title, sw_pub_id)

    existing_pub_identifier = PublicationIdentifier.where(
      :identifier_type => 'PublicationItemId',
      :identifier_value => sw_pub_id).first

    if existing_pub_identifier.nil?
      pub = Publication.create(active: true, human_readable_title: title, year: year)
    else
      pub = existing_pub_identifier.publication
    end

    sul_pub_id = pub.id.to_s
    pub_hash[:sulpubid] = sul_pub_id
    pub_hash[:article_identifiers] << {:type => 'SULPubId', :id => sul_pub_id, :url => 'http://sulcap.stanford.edu/publications/' + sul_pub_id}
    pub.save   # to reset last updated value
    pub_hash[:last_updated] = pub.updated_at

    if mesh_values_for_pmids.nil? && ! pmid.nil?
      pub_hash[:mesh_headings] = get_mesh_from_pubmed([pmid])[pmid]
    else
      pub_hash[:mesh_headings] = mesh_values_for_pmids[pmid]
    end

    add_contribution_to_db(sul_pub_id, author.id, author.cap_profile_id, contrib_status)
    add_all_known_contributions_to_pub_hash(pub, pub_hash)

    add_identifiers_to_db(pub_hash[:article_identifiers], pub)
    add_all_known_identifiers_to_pub_hash(pub_hash, pub)

    #add_searchable_author_names_to_db(pub_hash, pub)

     add_formatted_citations(pub_hash)

    pub.json = generate_json_for_pub(pub_hash)

    pub.xml = generate_xml_for_pub(pub_hash)

    pub.save
  end

  def index_manual_contributions_in_solr

Publication.find_each(:include => :source_record, :conditions => "source_record.source_name = 'user' ") do | publication |
  
   # :id=>1, :firstname=>'james', :lastname=>'chartrand', :middlename=>'colin', :title=>'where is it?', :bibjson=>'somebibjson', :source=>'whee', :year=>'1456'
    pub_hash = JSON.parse(publication.json)
        #puts pub_hash.to_s
=begin        
        
        I NEED A TEST CASE HERE, WITH A PUBLICATION FACTORY THAT WILL GENERATE A PUBLICATION WITH JSON WITH A
        FULLY POPULATED AUTHOR LIST, INCLUDING MIDDLENAME, ETC.  

          - create the factory, then write the rspec test to GET the publication, and one to test the solr indexing
=end
        pub_hash[author].each do |author| 
            last_name = ""
            rest_of_name = ""
            author.split(',').each_with_index do |name_part, index|
                if index == 0
                  last_name = name_part
                elsif name_part.length == 1
                  rest_of_name << ' ' << name_part << '.'
                elsif name_part.length > 1
                  rest_of_name << ' ' << name_part
                end
            end
     
        solr_doc = {
          id: publication.id, 
          title: publication.human_readable_title,
          bibjson: publication.json,
          year: publication.year

        }
        
            
        end
         
        solr = RSolr.connect :url => 'http://localhost:8080/solr'
        solr.add solr_doc, :add_attributes => {:commitWithin => 10}
      end
        #solr.commit
  end
  

  def get_cap_author(cap_profile_id)
    author = Author.where(cap_profile_id: cap_profile_id).first_or_create()
    # PopulationMembership.where(author_id: author.id, cap_profile_id: cap_profile_id, population_name: 'cap').first_or_create()
    author
  end

  def add_contribution_to_db(pub_id, author_id, cap_profile_id, contrib_status)
    Contribution.where(:author_id => author_id, :publication_id => pub_id).first_or_create(
      cap_profile_id: cap_profile_id,
    confirmed_status: contrib_status)
  end

  def add_all_known_contributions_to_pub_hash(publication, pub_hash)
    contributions = Array.new
    publication.contributions.each do |contrib|
      contributions <<
        {:cap_profile_id => contrib.cap_profile_id,
         :sul_author_id => contrib.author_id,
         :status => contrib.confirmed_status}

        end
    pub_hash[:contributions] = contributions
  end

  def save_source_record(data_to_save, record_type, pub_title, source_record_id)
    source_record = SourceRecord.where(:original_source_id => source_record_id, :source_name => record_type).
    first_or_create(
      :human_readable_title => pub_title,
    )
    source_record.source_data = data_to_save
    source_record.save
  end


  def add_identifiers_to_db(identifiers_hash, publication)
    identifiers_hash.each do |identifier|
      publication.publication_identifiers.where(
        :identifier_type => identifier[:type],
        :identifier_value => identifier[:id]).
        first_or_create(:certainty => 'confirmed', :identifier_uri => identifier[:url])
    end
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

  def add_all_known_identifiers_to_pub_hash(pub_hash, publication)
    identifiers = Array.new
    publication.publication_identifiers.each do |identifier|
      ident_hash = Hash.new
      ident_hash[:type] = identifier.identifier_type unless identifier.identifier_type.nil?
      ident_hash[:id] = identifier.identifier_value unless identifier.identifier_value.nil?
      ident_hash[:url] = identifier.identifier_uri unless identifier.identifier_uri.nil?
        identifiers << ident_hash
    end
    pub_hash[:article_identifiers] = identifiers
  end



  def convert_sw_publication_doc_to_hash(publication)

    record_as_hash = Hash.new
    record_as_hash[:pmid] = publication.xpath("PMID").text unless publication.xpath("PMID").nil?
    record_as_hash[:sw_id] = publication.xpath("PublicationItemID").text
    record_as_hash[:provenance] = "sciencewire"
    record_as_hash[:title] = publication.xpath("Title").text
    record_as_hash[:the_abstract] = publication.xpath("Abstract").text
    record_as_hash[:authors] = publication.xpath('AuthorList').text.split('|')
    record_as_hash[:keywords] = publication.xpath('KeywordList').text.split('|')
    record_as_hash[:documentTypes] = publication.xpath("DocumentTypeList").text.split('|')
    record_as_hash[:documentCategory] = publication.xpath("DocumentCategory").text
    record_as_hash[:numberOfReferences] = publication.xpath("NumberOfReferences").text
    record_as_hash[:timesCited] = publication.xpath("TimesCited").text
    record_as_hash[:timesNotSelfCited] = publication.xpath("TimesNotSelfCited").text

    # the journal info
    record_as_hash[:publicationTitle] = publication.xpath('PublicationSourceTitle').text
    record_as_hash[:publicationVolume] = publication.xpath('Volume').text
    record_as_hash[:publicationIssue] = publication.xpath('Issue').text
    record_as_hash[:publicationPagination] = publication.xpath('Pagination').text
    record_as_hash[:publicationDate] = publication.xpath('PublicationDate').text
    record_as_hash[:publicationYear] = publication.xpath('PublicationYear').text
    record_as_hash[:publicationImpactFactor] = publication.xpath('PublicationImpactFactor').text
    record_as_hash[:publicationSubjectCategories] = publication.xpath('PublicationSubjectCategoryList').text.split('|')
    record_as_hash[:publicationIdentifiers] = [
      {:type => 'issn', :id => publication.xpath('ISSN').text, :url => 'http://searchworks.stanford.edu/?search_field=advanced&number=' + publication.xpath('ISSN').text},
      {:type => 'doi', :id => publication.xpath('DOI').text, :url => 'http://dx.doi.org/' + publication.xpath('DOI').text}
    ]
    record_as_hash[:publicationConferenceStartDate] = publication.xpath('ConferenceStartDate').text
    record_as_hash[:publicationConferenceEndDate] = publication.xpath('ConferenceEndDate').text
    record_as_hash[:rank] =  publication.xpath('Rank').text
    record_as_hash[:ordinalRank] = publication.xpath('OrdinalRank').text
    record_as_hash[:normalizedRank] = publication.xpath('NormalizedRank').text
    record_as_hash[:newPublicationId] = publication.xpath('NewPublicationItemID').text
    record_as_hash[:isObsolete] = publication.xpath('IsObsolete').text
    record_as_hash[:copyrightPublisher] =  publication.xpath('CopyrightPublisher').text
    record_as_hash[:copyrightCity] = publication.xpath('CopyrightCity').text

    identifier_hash = Array.new
    identifier_hash << {:type =>'PMID', :id => publication.at_xpath("PMID").text, :url => 'http://www.ncbi.nlm.nih.gov/pubmed/' + publication.xpath("PMID").text } unless publication.at_xpath("PMID").nil?
    identifier_hash << {:type => 'WoSItemID', :id => publication.at_xpath("WoSItemID").text, :url => 'http://ws.isiknowledge.com/cps/openurl/service?url_ver=Z39.88-2004&rft_id=info:ut/' + publication.xpath("WoSItemID").text} unless publication.at_xpath("WoSItemID").nil?
    identifier_hash << {:type => 'PublicationItemID', :id => publication.at_xpath("PublicationItemID").text} unless publication.at_xpath("PublicationItemID").nil?
    record_as_hash[:article_identifiers] = identifier_hash

    record_as_hash
  end


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

  def generate_json_for_pub(pub_hash)
      json_string = Jbuilder.encode do |json|
      unless pub_hash[:article_identifiers].blank?
        json.identifer(pub_hash[:article_identifiers]) do | identifier |
          if identifier.has_key?(:url)
            json.(identifier, :id, :type, :url)
          else
            json.(identifier, :id, :type)
          end
        end
      end
      json.title pub_hash[:title] unless pub_hash[:title].blank?
      json.abstract pub_hash[:the_abstract] unless pub_hash[:the_abstract].blank?
      json.keywords pub_hash[:keywords] unless pub_hash[:keywords].blank?
      json.author pub_hash[:authors] do | author |
        json.name author
      end
      # json.authorsAnded
      json.provenance pub_hash[:provenance] unless pub_hash[:provenance].blank?
      json.documenttypes pub_hash[:documentTypes] unless pub_hash[:documentTypes].blank?
      json.category pub_hash[:documentCategory] unless pub_hash[:documentCategory].blank?
      json.timescited pub_hash[:timesCited] unless pub_hash[:timesCited].blank?
      json.timesnotselfcited pub_hash[:timesNotSelfCited] unless pub_hash[:timesNotSelfCited].blank?
      json.rank pub_hash[:rank] unless pub_hash[:rank].blank?
      json.ordinalrank pub_hash[:ordinalRank] unless pub_hash[:ordinalRank].blank?
      json.normalizedrank pub_hash[:normalizedRank] unless pub_hash[:normalizedRank].blank?
      json.newpublicationid pub_hash[:newPublicationId] unless pub_hash[:newPublicationId].blank?
      json.isobsolete pub_hash[:isObsolete] unless pub_hash[:isObsolete].blank?
      json.publisher pub_hash[:copyrightPublisher] unless pub_hash[:copyrightPublisher].blank?
      json.address pub_hash[:copyrightCity] unless pub_hash[:copyrightCity].blank?
      unless pub_hash[:mesh_headings].blank?
        json.mesh(pub_hash[:mesh_headings]) do | heading |
          json.descriptor(heading[:descriptor])  do |descriptor|
            json.(descriptor, :major, :name)
          end
          unless heading[:qualifier].empty?
            json.qualifier(heading[:qualifier]) do |qualifier|
              json.(qualifier, :major, :name)
            end
          end
        end
      end
      json.journal do | json |
        json.name pub_hash[:publicationTitle]  unless pub_hash[:publicationTitle].blank?
        json.volume pub_hash[:publicationVolume]  unless pub_hash[:publicationVolume].blank?
        json.issue pub_hash[:publicationIssue]  unless pub_hash[:publicationIssue].blank?
        json.pages pub_hash[:publicationPagination]  unless pub_hash[:publicationPagination].blank?
        json.date pub_hash[:publicationDate]  unless pub_hash[:publicationDate].blank?
        json.year pub_hash[:publicationYear]  unless pub_hash[:publicationYear].blank?
        json.publicationimpactfactor pub_hash[:publicationImpactFactor]  unless pub_hash[:publicationImpactFactor].blank?
        json.subjectcategories pub_hash[:publicationSubjectCategories]  unless pub_hash[:publicationSubjectCategories].blank?
        unless pub_hash[:publicationIdentifiers].blank?
          json.identifer(pub_hash[:publicationIdentifiers]) do | identifier |
            if identifier.has_key?(:url)
              json.(identifier, :id, :type, :url)
            else
              json.(identifier, :id, :type)
            end
          end
        end
        json.conferencestartdate pub_hash[:publicationConferenceStartDate]  unless pub_hash[:publicationConferenceStartDate].blank?
        json.conferenceenddate pub_hash[:publicationConferenceEndDate]  unless pub_hash[:publicationConferenceEndDate].blank?
      end
      unless pub_hash[:contributions].blank?
        json.contributions(pub_hash[:contributions]) do | contribution |
          json.(contribution, :sul_author_id, :cap_profile_id, :status)
        end
      end
      json.chicago pub_hash[:chicago_citation]  unless pub_hash[:chicago_citation].blank?
      json.apa pub_hash[:apa_citation]  unless pub_hash[:apa_citation].blank?
      json.mla pub_hash[:mla_citation]  unless pub_hash[:mla_citation].blank?
      json.lastupdated pub_hash[:last_update] unless pub_hash[:last_update].blank?

    end
   # puts "encoding after jbuilder: " + json_string.encoding.to_s
   #switch escaped unicode back to utf8
    json_string.gsub!(/\\u([0-9a-z]{4})/) {|s| [$1.to_i(16)].pack("U")}
    json_string.force_encoding(::Encoding::UTF_8) if json_string.respond_to?(:force_encoding)
   # puts "trying to force utf8: " + json_string.encoding.to_s
   # puts "string with utf8: " + json_string
    json_string
    
  end

  def generate_xml_for_pub(pub_hash)
    xmlbuilder = Nokogiri::XML::Builder.new do |newPubDoc|

      newPubDoc.publication {

        newPubDoc.title pub_hash[:title]
        pub_hash[:authors].each do | authorName |
          newPubDoc.author {
            newPubDoc.name pub_hash[:authorName]
          }
        end
        newPubDoc.abstract_ pub_hash[:the_abstract]
        pub_hash[:keywords].each do | keyword |
          newPubDoc.keyword keyword
        end
        pub_hash[:documentTypes].each do | docType |
          newPubDoc.type docType
        end
        newPubDoc.category pub_hash[:documentCategory]
        newPubDoc.journal {
          newPubDoc.title pub_hash[:publicationTitle]
        }

        # also add the last_update_at_source, last_retrieved_from_source,
      }


    end
    xmlbuilder.to_xml

  end

  def add_formatted_citations(pub_hash)
    #[{"id"=>"Gettys90", "type"=>"article-journal", "author"=>[{"family"=>"Gettys", "given"=>"Jim"}, {"family"=>"Karlton", "given"=>"Phil"}, {"family"=>"McGregor", "given"=>"Scott"}], "title"=>"The {X} Window System, Version 11", "container-title"=>"Software Practice and Experience", "volume"=>"20", "issue"=>"S2", "abstract"=>"A technical overview of the X11 functionality.  This is an update of the X10 TOG paper by Scheifler \\& Gettys.", "issued"=>{"date-parts"=>[[1990]]}}]
    chicago_csl_file = Rails.root.join('app', 'data', 'chicago-author-date.csl')

    authors_for_citeproc = []
    pub_hash[:authors].each do |author|
      last_name = ""
      rest_of_name = ""
      author.split(',').each_with_index do |name_part, index|
        if index == 0
          last_name = name_part
        elsif name_part.length == 1
          rest_of_name << ' ' << name_part << '.'
        elsif name_part.length > 1
          rest_of_name << ' ' << name_part
        end
      end
      authors_for_citeproc << {"family" => last_name, "given" => rest_of_name}
    end

    cit_data = [{"id" => "test89",
                 "type"=>"article-journal",
                 "author"=>authors_for_citeproc,
                 "title"=>pub_hash[:title],
                 "container-title"=>pub_hash[:publicationTitle],
                 "volume"=>pub_hash[:publicationVolume],
                 "issue"=>pub_hash[:publicationIssue],
                 "abstract"=>pub_hash[:the_abstract],
                 "issued"=>{"date-parts"=>[[pub_hash[:publicationYear]]]}
                 }]

    # chicago_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/chicago-author-date.csl', :format => 'html')
    # apa_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/apa.csl', :format => 'html')
    # mla_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/mla.csl', :format => 'html')
    pub_hash[:apa_citation] = CiteProc.process(cit_data, :style => :apa, :format => 'html')
    pub_hash[:mla_citation] = CiteProc.process(cit_data, :style => :mla, :format => 'html')
    chicago_citation = CiteProc.process(cit_data, :style => chicago_csl_file, :format => 'html')
    pub_hash[:chicago_citation] = chicago_citation
    
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
              <Value>' + year + '</Value>
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
     <MaximumRows>50</MaximumRows>
    </query>
    ]]>'
    xml_results = query_sciencewire(xml_query)

    xml_results.xpath('//PublicationItem').each do |sw_xml_doc|
      puts sw_xml_doc.to_xml
          result << generate_json_for_pub(convert_sw_publication_doc_to_hash(sw_xml_doc))       
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

  def get_mesh_from_pubmed(pmid_list)
    mesh_values_for_all_records = Hash.new
    pmidValuesForPost = pmid_list.collect { |pmid| "&id=#{pmid}"}.join
    #start_time = Time.now
    http = Net::HTTP.new("eutils.ncbi.nlm.nih.gov")
    request = Net::HTTP::Post.new("/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml")
    request.body = pmidValuesForPost
    #puts "PubMed call took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
    #start_time = Time.now
    Nokogiri::XML(http.request(request).body).xpath('//PubmedArticle').each do |publication|
      pmid = publication.xpath('MedlineCitation/PMID').text
      mesh_headings_for_record = []
      publication.xpath('MedlineCitation/MeshHeadingList/MeshHeading').each do |mesh_heading|
        descriptors = []
        qualifiers = []
        mesh_heading.xpath('DescriptorName').each do |descriptor_name|
          descriptors << {:major => descriptor_name.attr('MajorTopicYN'), :name => descriptor_name.text}
        end
        mesh_heading.xpath('QualifierName').each do |qualifier_name|
          qualifiers << {:major => qualifier_name.attr('MajorTopicYN'), :name => qualifier_name.text}
        end
        mesh_headings_for_record << { :descriptor => descriptors, :qualifier => qualifiers }
      end
      mesh_values_for_all_records[pmid] = mesh_headings_for_record
    end
    #puts "extracting mesh from pubmed results took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)

    mesh_values_for_all_records
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

    unless seed_list.empty?
      bod << '<PublicationItemIds>'
      bod << seed_list.collect { |pubId| "<int>#{pubId}</int>"}.join
      bod << '</PublicationItemIds>'
    end

    unless email_list.empty?
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
