# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Publication.delete_all


require 'nokogiri'

http = Net::HTTP.new("sciencewirerest.discoverylogic.com", 443)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER
http.ssl_version = :SSLv3
request = Net::HTTP::Get.new("/PublicationCatalog/PublicationItems?format=xml&publicationItemIDs=1073592,8419261")
request["Content_Type"] = "text/xml"
request["LicenseID"] = "***REMOVED***"
request["Host"] = "sciencewirerest.discoverylogic.com"
request["Connection"] = "Keep-Alive"

response = http.request(request)

#f = File.open(Rails.root.join('app', 'data', 'SW_MatchedPublicationItemIdsForAuthor.xml'))
scienceWireDoc = Nokogiri::XML(response.body)
#f.close

publications = scienceWireDoc.xpath("//PublicationItem")
scienceWireDoc.xpath('//PublicationItem').each do |publication|
	title = publication.xpath("Title").text
	sciencewireId = publication.xpath("PublicationItemID")

	builder = Nokogiri::XML::Builder.new do |newPubDoc|
		
			newPubDoc.publication {
				newPubDoc.title title
				publication.xpath('AuthorList').text.split('|').each do | authorName | 
					newPubDoc.author {
						newPubDoc.name authorName
					}
				end
				publication.abstract publication.xpath("Abstract").text
				publication.xpath('KeywordList').text.split('|').each do | keyword |
					newPubDoc.keyword keyword
				end
				publication.xpath('DocumentTypeList').text.split('|').each do | docType |
					newPubDoc.document-type docType
				end
				publication.document-category publication.xpath("DocumentCategory").text
			}
		

	end
	theXML = builder.to_xml
	theJSON = JSON.pretty_generate(Hash.from_xml(theXML))
    Publication.create( active: true, human_readable_title: title, xml: theXML, json: theJSON )
end



=begin
 <PublicationItem>
   <PublicationItemID>7099103</PublicationItemID>
   <Title>Peak height precision in Hadamard transform time-of-flight mass spectra</Title>
   <Abstract>Hadamard transform (HT) time-of-flight mass spectrometry (TOFMS) is a multiplexing technique that offers high duty cycle for the mass analysis of continuous ion sources. The multiplexing advantage is maximized when spectral noise is independent of signal intensity. For conditions in which shot noise predominates, the variance in each peak is a function of the population of all measured species. We develop expressions for the performance of a HT-TOF mass spectrometer based on Poissonian statistics for the arrival times of ions at the detector. These expressions and complementary probabilistic simulations are used to estimate the magnitude of the baseline noise as a function of mass spectral features and acquisition conditions. Experiment validates the predictions that noise depends on the total number of ions in the acquired spectrum, and the achieved signal-to-noise ratio for a given species depends on its relative population. We find that for HT-TOFMS experiments encoded with an n-order binary off-on sequence that contains N = 2(n) - 1 elements, the peak height precision, which is the peak intensity divided by its standard deviation, is greater than that of an equivalent conventional TOF experiment by a factor of root N/2 times the square root of the fractional abundance of the peak of interest. Thus, HT-TOFMS is superior to conventional TOF for all species whose fractional abundance F-i exceeds 2/N, which for a typical N value of 2047 corresponds to Fi &gt; 0.001. HT-TOF mass spectra collected at 2500 per second demonstrates the method's capability of monitoring transient processes not possible by conventional means. (c) 2005 American Society for Mass Spectrometry.</Abstract>
   <AuthorList>Kimmel,J,R|Yoon,O,K|Zuleta,I,A|Trapp,O,|Zare,R,N</AuthorList>
   <AuthorCount>5</AuthorCount>
   <KeywordList>MULTIPLEX|SIGNAL|SPECTROMETRY|ELECTROSPRAY</KeywordList>
   <DocumentTypeList>Article</DocumentTypeList>
   <DocumentCategory>Journal Document</DocumentCategory>
   <NumberOfReferences>18</NumberOfReferences>
   <TimesCited>11</TimesCited>
   <TimesNotSelfCited>5</TimesNotSelfCited>
   <PMID xsi:nil="true" />
   <WoSItemID>000230045500016</WoSItemID>
   <PublicationSourceTitle>JOURNAL OF THE AMERICAN SOCIETY FOR MASS SPECTROMETRY</PublicationSourceTitle>
   <Volume>16</Volume>
   <Issue>7</Issue>
   <Pagination>1117-1130</Pagination>
   <PublicationDate>2005-07-01T00:00:00</PublicationDate>
   <PublicationYear>2005</PublicationYear>
   <PublicationType>Journal</PublicationType>
   <PublicationImpactFactor>3.625</PublicationImpactFactor>
   <PublicationSubjectCategoryList>Chemistry, Analytical|Chemistry, Physical|Spectroscopy</PublicationSubjectCategoryList>
   <ISSN>1044-0305</ISSN>
   <DOI>10.1016/j.jasms.2005.02.022</DOI>
   <ConferenceStartDate xsi:nil="true" />
   <ConferenceEndDate xsi:nil="true" />
   <Rank xsi:nil="true" />
   <OrdinalRank>2</OrdinalRank>
   <NormalizedRank xsi:nil="true" />
   <NewPublicationItemID>7099103</NewPublicationItemID>
   <IsObsolete>false</IsObsolete>
   <CopyrightPublisher>ELSEVIER SCIENCE INC</CopyrightPublisher>
   <CopyrightCity>NEW YORK</CopyrightCity>
 </PublicationItem>
=end

# 4. and then query pubmed to get the MESH:


# url = "http://www.ncbi.nlm.nih.gov/pubmed/?term=NS044283[GR]&dispmax=200&report=xml"
# doc = Nokogiri::XML(open(url))
# pre = doc.xpath('//pre')
# xml = "<root>" + pre.text + "</root>"
# contents = Nokogiri::XML(xml)
# articles = contents.css('PubmedArticle')
# puts contents.css('ArticleTitle').map{|x| x.content}.count   

# 5. and add profileIds as 'contributions')




sampleBibJSON = '{
    "metadata": {
        "_created": "20121121190112",  
        "description": "sample of bibjson output taken from bisoup.net for cap experimentation", 
        "format": "bibtex",  
        "license": "http://www.opendefinition.org/licenses/cc-zero", 
        "query": "http://publication?pop=cap", 
        "records": 20
    }, 
    "records": [
        {
            "_created": "20121121190118", 
            "_id": "7870b3032a6c4ce7a9c4c1f846cf7276", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "JenningsJohnT", 
                    "name": "Jennings, John T"
                }, 
                {
                    "id": "KrogmannLars", 
                    "name": "Krogmann, Lars"
                }, 
                {
                    "id": "MewStevenL", 
                    "name": "Mew, Steven L"
                }
            ], 
            "citeulike-article-id": "11571676", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305268600007", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jun", 
            "number": "3349", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Hyptia deansi sp nov., the first record of Evaniidae (Hymenoptera) from Mexican amber", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305268600007", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "fb30ce59b6279a557e1bfba2bf0acc0d", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "RichardsonBarryJ", 
                    "name": "Richardson, Barry J"
                }, 
                {
                    "id": "GunterNicoleL", 
                    "name": "Gunter, Nicole L"
                }
            ], 
            "citeulike-article-id": "11571675", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305328600001", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jun", 
            "number": "3350", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Revision of Australian jumping spider genus Servaea Simon 1887 (Aranaea: Salticidae) including use of DNA sequence data and predicted distributions", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305328600001", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "1a3cc30a512c129cf80d26485c6aba45", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "LezamaAntonioQ", 
                    "name": "Lezama, Antonio Q"
                }, 
                {
                    "id": "TriquesMauroL", 
                    "name": "Triques, Mauro L"
                }, 
                {
                    "id": "SantosPatriciaS", 
                    "name": "Santos, Patricia S"
                }
            ], 
            "citeulike-article-id": "11571674", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305759300006", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jun", 
            "number": "3352", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Trichomycterus argos (Teleostei: Siluriformes: Trichomycteridae), a new species from the Doce River Basin, Eastern Brazil", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305759300006", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "e0961e3187ff5a583b63661a5679f225", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "SparksJohnS", 
                    "name": "Sparks, John S"
                }, 
                {
                    "id": "LoisellePaulV", 
                    "name": "Loiselle, Paul V"
                }, 
                {
                    "id": "BaldwinZacharyH", 
                    "name": "Baldwin, Zachary H"
                }
            ], 
            "citeulike-article-id": "11571673", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305759300002", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jun", 
            "number": "3352", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Rediscovery and phylogenetic placement of the endemic Malagasy cichlid Ptychochromoides itasy (Teleostei: Cichlidae: Ptychochrominae)", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305759300002", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "f36e0317b99453f27534ff7bd8b81264", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "EberleJonas", 
                    "name": "Eberle, Jonas"
                }, 
                {
                    "id": "TaenzlerRene", 
                    "name": "Taenzler, Rene"
                }, 
                {
                    "id": "RiedelAlexander", 
                    "name": "Riedel, Alexander"
                }
            ], 
            "citeulike-article-id": "11571672", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305881000001", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jun", 
            "number": "3355", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Revision and phylogenetic analysis of the Papuan weevil genus Thyestetha Pascoe (Coleoptera, Curculionidae, Cryptorhynchinae)", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305881000001", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "0740e3ed686989383e293dd77b691618", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "LiJing", 
                    "name": "Li, Jing"
                }, 
                {
                    "id": "XueDayong", 
                    "name": "Xue, Dayong"
                }, 
                {
                    "id": "HanHongxiang", 
                    "name": "Han, Hongxiang"
                }, 
                {
                    "id": "GalsworthyAnthonyC", 
                    "name": "Galsworthy, Anthony C"
                }
            ], 
            "citeulike-article-id": "11571671", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305881600001", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jun", 
            "number": "3357", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Taxonomic review of Syzeuxis Hampson, 1895, with a discussion of biogeographical aspects (Lepidoptera, Geometridae, Larentiinae)", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305881600001", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "ea6df90c970adc7d91c7f4af6958eb6e", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "SunNing", 
                    "name": "Sun, Ning"
                }, 
                {
                    "id": "LiBin", 
                    "name": "Li, Bin"
                }, 
                {
                    "id": "TuLihong", 
                    "name": "Tu, Lihong"
                }
            ], 
            "citeulike-article-id": "11571670", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305881800002", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jun", 
            "number": "3358", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Ternatus, a new spider genus from China with a cladistic analysis and comments on its phylogenetic placement (Araneae: Linyphiidae)", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305881800002", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "f494864c633b1cb3f174a51e1c4aad65", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "CurielJosefina", 
                    "name": "Curiel, Josefina"
                }, 
                {
                    "id": "MorroneJuanJ", 
                    "name": "Morrone, Juan J"
                }
            ], 
            "citeulike-article-id": "11571669", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305882400005", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jun", 
            "number": "3361", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Association of larvae and adults of Mexican species of Macrelmis (Coleoptera: Elmidae): a preliminary analysis using DNA sequences", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305882400005", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "db761c1eb22431214f70488543604149", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "PyoJooyeon", 
                    "name": "Pyo, Jooyeon"
                }, 
                {
                    "id": "LeeTaekjun", 
                    "name": "Lee, Taekjun"
                }, 
                {
                    "id": "ShinSook", 
                    "name": "Shin, Sook"
                }
            ], 
            "citeulike-article-id": "11571668", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305937400009", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3368, SI", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Two newly recorded invasive alien ascidians (Chordata, Tunicata, Ascidiacea) based on morphological and molecular phylogenetic analysis in Korea", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305937400009", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "80435753d0861158393dae7d0f416619", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "KimSeong-Yong", 
                    "name": "Kim, Seong-Yong"
                }
            ], 
            "citeulike-article-id": "11571667", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305936900001", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3366", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Phylogenetic Systematics of the Family Pentacerotidae (Actinopterygii: Order Perciformes)", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305936900001", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "8fe1c8c59ef87536c0a228b1df3f34c4", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "LonsdaleOwen", 
                    "name": "Lonsdale, Owen"
                }, 
                {
                    "id": "MarshallStephenA", 
                    "name": "Marshall, Stephen A"
                }
            ], 
            "citeulike-article-id": "11571666", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305937600001", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3370", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Sobarocephala (Diptera: Clusiidae: Sobarocesphalinae)-Subgeneric classification and Revision of the New World species", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305937600001", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "a1dfab4d706319aca975e8e56203238a", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "GustafssonDanielR", 
                    "name": "Gustafsson, Daniel R"
                }, 
                {
                    "id": "OlssonUrban", 
                    "name": "Olsson, Urban"
                }
            ], 
            "citeulike-article-id": "11571665", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305940500001", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3377", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "The ``Very Thankless Task'': Revision of Lunaceps Clay and Meinertzhagen, 1939 (Insecta: Phthiraptera: Ischnocera: Philopteridae), with descriptions of six new species and one new subspecies", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305940500001", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "a32f439379b96f62e36e3a088b9e95c7", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "Ferrer-SuayMar", 
                    "name": "Ferrer-Suay, Mar"
                }, 
                {
                    "id": "Paretas-MartinezJordi", 
                    "name": "Paretas-Martinez, Jordi"
                }, 
                {
                    "id": "SelfaJesus", 
                    "name": "Selfa, Jesus"
                }, 
                {
                    "id": "Pujade-VillarJuli", 
                    "name": "Pujade-Villar, Juli"
                }
            ], 
            "citeulike-article-id": "11571664", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305940200001", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3376", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Taxonomic and synonymic world catalogue of the Charipinae and notes about this subfamily (Hymenoptera: Cynipoidea: Figitidae)", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305940200001", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "80a09e7bec4637d1e365cb435daf5590", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "DankittipakulPakawin", 
                    "name": "Dankittipakul, Pakawin"
                }, 
                {
                    "id": "JocqueRudy", 
                    "name": "Jocque, Rudy"
                }, 
                {
                    "id": "SingtripopTippawan", 
                    "name": "Singtripop, Tippawan"
                }
            ], 
            "citeulike-article-id": "11571663", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305938200001", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3369", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Systematics and biogeography of the spider genus Mallinella Strand, 1906, with descriptions of new species and new genera from Southeast Asia (Araneae, Zodariidae)", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305938200001", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "a01fd1ab4c1ab265e21ec1f0a8864e21", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "ColomaLuisA", 
                    "name": "Coloma, Luis A"
                }, 
                {
                    "id": "Carvajal-EndaraSofia", 
                    "name": "Carvajal-Endara, Sofia"
                }, 
                {
                    "id": "DuenasJuanF", 
                    "name": "Duenas, Juan F"
                }, 
                {
                    "id": "Paredes-RecaldeArturo", 
                    "name": "Paredes-Recalde, Arturo"
                }, 
                {
                    "id": "Morales-MiteManuel", 
                    "name": "Morales-Mite, Manuel"
                }, 
                {
                    "id": "Almeida-ReinosoDiego", 
                    "name": "Almeida-Reinoso, Diego"
                }, 
                {
                    "id": "TapiaElicioE", 
                    "name": "Tapia, Elicio E"
                }, 
                {
                    "id": "HutterCarlR", 
                    "name": "Hutter, Carl R"
                }, 
                {
                    "id": "ToralEduardo", 
                    "name": "Toral, Eduardo"
                }, 
                {
                    "id": "GuayasaminJuanM", 
                    "name": "Guayasamin, Juan M"
                }
            ], 
            "citeulike-article-id": "11571662", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305935900001", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3364", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Molecular phylogenetics of stream treefrogs of the Hyloscirtus larinopygion group (Anura: Hylidae), and description of two new species from Ecuador", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305935900001", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "b175959d31df8526c28fa65f997df23b", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "CarranzaSalvador", 
                    "name": "Carranza, Salvador"
                }, 
                {
                    "id": "ArnoldEdwinN", 
                    "name": "Arnold, Edwin N"
                }
            ], 
            "citeulike-article-id": "11571661", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305940800001", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3378", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "A review of the geckos of the genus Hemidactylus (Squamata: Gekkonidae) from Oman based on morphology, mitochondrial and nuclear data, with descriptions of eight new species", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305940800001", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "02ec852dc9787d0e0efbda3c98c8993f", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "MooreGlennI", 
                    "name": "Moore, Glenn I"
                }, 
                {
                    "id": "HutchinsJBarry", 
                    "name": "Hutchins, J Barry"
                }, 
                {
                    "id": "OkamotoMakoto", 
                    "name": "Okamoto, Makoto"
                }
            ], 
            "citeulike-article-id": "11571660", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000305972200002", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3380", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "A new species of the deepwater clingfish genus Kopua (Gobiesociformes: Gobiesocidae) from the East China Sea-an example of antitropicality?", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000305972200002", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "1019e43d8d7cc65266c3875a50fe76e0", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "BlackburnDavidC", 
                    "name": "Blackburn, David C"
                }, 
                {
                    "id": "WakeDavidB", 
                    "name": "Wake, David B"
                }
            ], 
            "citeulike-article-id": "11571659", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000306071400002", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3381", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Additions and corrections", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000306071400002", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "3f37b599e1f94c96bf2a1b330da51d07", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "Gomez-BerningMaria", 
                    "name": "Gomez-Berning, Maria"
                }, 
                {
                    "id": "KoehlerFrank", 
                    "name": "Koehler, Frank"
                }, 
                {
                    "id": "GlaubrechtMatthias", 
                    "name": "Glaubrecht, Matthias"
                }
            ], 
            "citeulike-article-id": "11571658", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000306071400001", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3381", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "CATALOGUE OF THE NOMINAL TAXA OF MESOAMERICAN PACHYCHILIDAE (MOLLUSCA: CAENOGASTROPODA)", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000306071400001", 
            "year": "2012"
        }, 
        {
            "_created": "20121121190118", 
            "_id": "4eddc26df7ae2c11582c9b4836bdee53", 
            "_last_modified": "20121121190118", 
            "author": [
                {
                    "id": "HarveyFrancesSB", 
                    "name": "Harvey, Frances S B"
                }, 
                {
                    "id": "FramenauVolkerW", 
                    "name": "Framenau, Volker W"
                }, 
                {
                    "id": "WojcieszekJanineM", 
                    "name": "Wojcieszek, Janine M"
                }, 
                {
                    "id": "RixMichaelG", 
                    "name": "Rix, Michael G"
                }, 
                {
                    "id": "HarveyMarkS", 
                    "name": "Harvey, Mark S"
                }
            ], 
            "citeulike-article-id": "11571657", 
            "collection": "zootaxa_sample", 
            "id": "ISI:000306166000003", 
            "journal": {
                "id": "ZOOTAXA", 
                "name": "ZOOTAXA"
            }, 
            "month": "jul", 
            "number": "3383", 
            "owner": "rossmounce", 
            "posted-at": "2012-10-29 11:03:14", 
            "priority": "2", 
            "title": "Molecular and morphological characterisation of new species in the trapdoor spider genus Aname (Araneae: Mygalomorphae: Nemesiidae) from the Pilbara bioregion of Western Australia", 
            "type": "article", 
            "url": "http://bibsoup.net/rossmounce/zootaxa_sample/ISI:000306166000003", 
            "year": "2012"
        }
    ]
}'  