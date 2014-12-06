# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Publication.delete_all


require 'nokogiri'
require 'citeproc'
require 'bibtex'

http = Net::HTTP.new("sciencewirerest.discoverylogic.com", 443)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER
request = Net::HTTP::Post.new("/PublicationCatalog/MatchedPublicationItemIdsForAuthor?format=xml")
request["Content_Type"] = "text/xml"
request["LicenseID"] = "***REMOVED***"
request["Host"] = "sciencewirerest.discoverylogic.com"
request["Connection"] = "Keep-Alive"
request["Expect"] = "100-continue"
request["Content-Type"] = "text/xml"
request.body = '<?xml version="1.0"?> <PublicationAuthorMatchParameters xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"> <Authors> <Author> <LastName>Zare</LastName> <FirstName>Richard</FirstName> <MiddleName>N</MiddleName> <City>Stanford</City> <State>CA</State> <Country>USA</Country> </Author> </Authors> <DocumentCategory>Journal Document</DocumentCategory> <Emails> <string>zare@stanford.edu</string> </Emails> <LimitToHighQualityMatchesOnly>false</LimitToHighQualityMatchesOnly> </PublicationAuthorMatchParameters>'

response = http.request(request)

commaSepIds = Nokogiri::XML(response.body).xpath('//PublicationItemID').map(&:text).join(',')

fullPubsRequest = Net::HTTP::Get.new("/PublicationCatalog/PublicationItems?format=xml&publicationItemIDs=" + commaSepIds)
fullPubsRequest["Content_Type"] = "text/xml"
fullPubsRequest["LicenseID"] = "***REMOVED***"
fullPubsRequest["Host"] = "sciencewirerest.discoverylogic.com"
fullPubsRequest["Connection"] = "Keep-Alive"

fullPubResponse = http.request(fullPubsRequest)

# also add call here to get MESH for each

#f = File.open(Rails.root.join('app', 'data', 'SW_MatchedPublicationItemIdsForAuthor.xml'))
#scienceWireDoc = Nokogiri::XML(response.body)
#f.close

#publications = scienceWireDoc.xpath("//PublicationItem")

Nokogiri::XML(fullPubResponse.body).xpath('//PublicationItem').each do |publication|


    title = publication.xpath("Title").text
    the_abstract = publication.xpath("Abstract").text
    authors = publication.xpath('AuthorList').text.split('|')
    keywords = publication.xpath('KeywordList').text.split('|')
    documentTypes = publication.xpath("DocumentTypeList").text.split('|')
    documentCategory = publication.xpath("DocumentCategory").text
    numberOfRefernces = publication.xpath("NumberOfReferences").text
    timesCited = publication.xpath("TimesCited").text
    timesNotSelfCited = publication.xpath("TimesNotSelfCited").text
    article_identifiers = [
        {:type =>'PMID', :id => publication.xpath("PMID").text, :url => 'http://www.ncbi.nlm.nih.gov/pubmed/' + publication.xpath("PMID").text },
        {:type => 'WoSItemID', :id => publication.xpath("WoSItemID").text, :url => 'http://wosuri/' + publication.xpath("WoSItemID").text},
        {:type => 'PublicationItemID', :id => publication.xpath("PublicationItemID").text, :url => 'http://sciencewireURI/' + publication.xpath("PublicationItemID").text}
    ]
    # the journal info
    publicationTitle = publication.xpath('PublicationSourceTitle').text
    publicationVolume = publication.xpath('Volume').text
    publicationIssue = publication.xpath('Issue').text
    publicationPagination = publication.xpath('Pagination').text
    publicationDate = publication.xpath('PublicationDate').text
    publicationYear = publication.xpath('PublicationYear').text
    publicationImpactFactor = publication.xpath('PublicationImpactFactor').text
    publicationSubjectCategories = publication.xpath('PublicationSubjectCategoryList').text.split('|')
    publicationIdentifiers = [
        {:type => 'issn', :id => publication.xpath('ISSN').text},
        {:type => 'doi', :id => publication.xpath('DOI').text}
    ]
    publicationConferenceStartDate = publication.xpath('ConferenceStartDate').text
    publicationConferenceEndDate = publication.xpath('ConferenceEndDate').text
    rank =  publication.xpath('Rank').text
    ordinalRank = publication.xpath('OrdinalRank').text
    normalizedRank = publication.xpath('NormalizedRank').text
    newPublicationId = publication.xpath('NewPublicationItemID').text
    isObsolete = publication.xpath('IsObsolete').text
    copyrightPublisher =  publication.xpath('CopyrightPublisher').text
    copyrightCity = publication.xpath('CopyrightCity').text

#[{"id"=>"Gettys90", "type"=>"article-journal", "author"=>[{"family"=>"Gettys", "given"=>"Jim"}, {"family"=>"Karlton", "given"=>"Phil"}, {"family"=>"McGregor", "given"=>"Scott"}], "title"=>"The {X} Window System, Version 11", "container-title"=>"Software Practice and Experience", "volume"=>"20", "issue"=>"S2", "abstract"=>"A technical overview of the X11 functionality.  This is an update of the X10 TOG paper by Scheifler \\& Gettys.", "issued"=>{"date-parts"=>[[1990]]}}]

authors_for_citeproc = []
authors.each do |author|
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
b = '@article{someId ' + publicationYear + '
   author = { peter jones },
   title = {' + title + '},
   journal = {' + publicationTitle +'},
   volume = {' + publicationVolume +'},
   number = {' + publicationIssue +'},
   year = {' + publicationYear +'},
   abstract = {' + the_abstract + '}
}'
#bib = BibTeX.parse(b)
#cit = bib.to_citeproc
cit = [{"id" => "test89", "type"=>"article-journal", "author"=>authors_for_citeproc,  "title"=>title, "container-title"=>publicationTitle, "volume"=>publicationVolume, "issue"=>publicationIssue, "abstract"=>the_abstract, "issued"=>{"date-parts"=>[[publicationYear]]}}]

chicago_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/chicago-author-date.csl', :format => 'html')
apa_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/apa.csl', :format => 'html')
mla_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/mla.csl', :format => 'html')


    contributions = [
        {:profileid => 'someId', :status => 'confirmed', :visibility => 'show'},
        {:profileid => 'someOtherId', :status => 'suspected', :visibility => 'show'},
        {:profileid => 'anotherId', :status => 'confirmed', :visibility => 'hide'}
    ]

    mesh_headings = [
        {
            :descriptor => [{:major => 'N', :name => 'ADP Ribose Transferases'}],
            :qualifier => [{:major => 'Y', :name => 'genetics'}]
        },
        {
            :descriptor => [{:major => 'N', :name => 'Acinetobacter'}],
            :qualifier => [{:major => 'Y', :name => 'drug effects'}, {:major => 'Y', :name => 'genetics'}]
        },
        {
            :descriptor => [{:major => 'N', :name => 'Bacteremia'}],
            :qualifier => [{:major => 'Y', :name => 'microbiology'}]
        },
    ]




    jsonString = Jbuilder.encode do |json|
        json.identifier(article_identifiers) do  |identifier|
                    json.(identifier, :id, :type, :url)
        end
        json.title title
        json.abstract the_abstract
        json.keywords keywords
        json.author authors do | author |
            json.name author
        end
        json.authorsAnded
        json.documenttypes documentTypes
        json.category documentCategory
        json.timescited timesCited
        json.timesnotselfcited timesNotSelfCited
        json.rank rank
        json.ordinalrank ordinalRank
        json.normalizedrank normalizedRank
        json.newpublicationid newPublicationId
        json.isobsolete isObsolete
        json.publisher copyrightPublisher
        json.address copyrightCity
        json.mesh(mesh_headings) do | heading |
            json.descriptor(heading[:descriptor])  do |descriptor|
                json.(descriptor, :major, :name)
            end
            json.qualifier(heading[:qualifier]) do |qualifier|
                json.(qualifier, :major, :name)
            end
        end
        json.journal do | json |
            json.name publicationTitle
            json.volume publicationVolume
            json.issue publicationIssue
            json.pages publicationPagination
            json.date publicationDate
            json.year publicationYear
            json.publicationimpactfactor publicationImpactFactor
            json.subjectcategories publicationSubjectCategories
            json.identifer(publicationIdentifiers) do | identifier |
                json.(identifier, :id, :type)
            end
            json.conferencestartdate publicationConferenceStartDate
            json.conferenceenddate publicationConferenceEndDate
        end
        json.contributions(contributions) do | contribution |
            json.(contribution, :profileid, :status, :visibility)
        end
        json.chicago chicago_citation
        json.apa apa_citation
        json.mla mla_citation


    end

=begin
“Duplicates”:[
    “pubId”:52234, “status”:”confirmed”, “visibility”:”show”},
    “pubId”:75432, “status”:”unconfirmed”, “visibility”:”show”, “duplicateWeighting”:65},
    “pubId”:99943, “status”:”rejected”, “visibility”:”hide”},
]
=end
	xmlbuilder = Nokogiri::XML::Builder.new do |newPubDoc|

			newPubDoc.publication {

				newPubDoc.title title
				authors.each do | authorName |
					newPubDoc.author {
						newPubDoc.name authorName
					}
				end
				newPubDoc.abstract_ the_abstract
				keywords.each do | keyword |
					newPubDoc.keyword keyword
				end
				documentTypes.each do | docType |
					newPubDoc.type docType
				end
				newPubDoc.category documentCategory
                newPubDoc.journal {
                    newPubDoc.title publicationTitle
                }

               # also add the last_update_at_source, last_retrieved_from_source,
			}


	end
	theXML = xmlbuilder.to_xml
	#theJSON = JSON.pretty_generate(Hash.from_xml(theXML))
    Publication.create( active: true, human_readable_title: title, xml: theXML, json: jsonString    )
end

