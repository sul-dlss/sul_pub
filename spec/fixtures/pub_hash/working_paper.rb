##
# A module for JSON data from the CAP-UI submitted to SUL-PUB when an author
# creates a new manual publication for various document types.
#
# These fixtures are used for mapping a CAP document type into a CSL document,see
# https://github.com/sul-dlss/sul-pub/wiki/Citation-Styles#mapping-doc-types-to-csl-item-types-and-fields
#
module PubHash
  module WorkingPaper
    # Example APA citation for a working paper (report):
    # Imberman, S., Kugler, A.D., & Sacerdote, B. (2009). Katrina’s children:
    # evidence on the structure of peer effects from hurricane evacuees (Working
    # Paper No. 15291). Retrieved from National Bureau of Economic Research
    # website: http://www.nber.org/papers/w15291
    #
    # The CiteProc result for the following document is close:
    # "
    #  Imberman, S., Kugler, A. D., &#38; Sacerdote, B. (2009). <i>Katrina's
    #  children: evidence on the structure of peer effects from hurricane evacuees</i> (No. 15291).
    #  National Bureau of Economic Research. Retrieved from http://www.nber.org/papers/w15291
    # "
    def working_paper_for_hurricanes_as_csl_report
      {
        'id' => 'sulpub',
        'type' => 'report', # working paper
        'author' => [
          { 'family' => 'Imberman', 'given' => 'Scott' },
          { 'family' => 'Kugler', 'given' => 'Adriana D.' },
          { 'family' => 'Sacerdote', 'given' => 'Bruce' },
        ],
        'title' => "Katrina's Children: Evidence on the Structure of Peer Effects from Hurricane Evacuees",
        'abstract' => "In 2005, hurricanes Katrina and Rita forced many children to relocate across the Southeast. While schools quickly enrolled evacuees, receiving families worried about the impact of evacuees on non-evacuee students. Data from Houston and Louisiana show that, on average, the influx of evacuees moderately reduced elementary math test scores in Houston. We reject linear-in-means models of peer effects and find evidence of a highly non-linear but monotonic model - student achievement improves with high ability and worsens with low ability peers. Moreover, exposure to undisciplined evacuees increased native absenteeism and disciplinary problems, supporting a \"bad apple\" model in behavior.\n\nDOI: 10.3386/w15291\n\nPublished: Scott A. Imberman & Adriana D. Kugler & Bruce I. Sacerdote, 2012. \"Katrina's Children: Evidence on the Structure of Peer Effects from Hurricane Evacuees,\" American Economic Review, American Economic Association, vol. 102(5), pages 2048-82, August.\n",
        'issued' => { 'date-parts' => [[ '2009' ]] }, # year: '2009',
        'collection-title' => 'NBER Working Paper Series',
        'number' => '15291',
        'page' => '1-55',
        'publisher' => 'National Bureau of Economic Research',
        'publisher-place' => 'Cambridge, MA',
        'URL' => 'http://www.nber.org/papers/w15291',
      }
    end

    ##
    # A 'workingPaper' submission from CAP, to be mapped into 'paper' CSL doc-type,
    # using a similar mapping to that used by Zotero, documented at
    # http://aurimasv.github.io/z2csl/typeMap.xml#map-report
    def working_paper_for_hurricanes
      {
        "identifier" => [],
        "title" => "Katrina's Children: Evidence on the Structure of Peer Effects from Hurricane Evacuees",
        "authorship" => [
          {
            "sul_author_id" => nil, "cap_profile_id" => 29_091, "featured" => false, "status" => "APPROVED", "visibility" => "PUBLIC", "additionalProperties" => {}
          }
        ],
        "year" => "2009",
        "abstract_restricted" =>
          "In 2005, hurricanes Katrina and Rita forced many children to relocate across the Southeast. While schools quickly enrolled evacuees, receiving families worried about the impact of evacuees on non-evacuee students. Data from Houston and Louisiana show that, on average, the influx of evacuees moderately reduced elementary math test scores in Houston. We reject linear-in-means models of peer effects and find evidence of a highly non-linear but monotonic model - student achievement improves with high ability and worsens with low ability peers. Moreover, exposure to undisciplined evacuees increased native absenteeism and disciplinary problems, supporting a \"bad apple\" model in behavior.\n\nDOI: 10.3386/w15291\n\nPublished: Scott A. Imberman & Adriana D. Kugler & Bruce I. Sacerdote, 2012. \"Katrina's Children: Evidence on the Structure of Peer Effects from Hurricane Evacuees,\" American Economic Review, American Economic Association, vol. 102(5), pages 2048-82, August.\n",
        "type" => "workingPaper",
        "provenance" => "CAP",
        "allAuthors" => "",
        "author" => [
          {
            "name" => "Imberman  Scott",
            "alternate" => [],
            "lastname" => "Imberman",
            "firstname" => "Scott",
            "middlename" => "",
            "role" => "author",
            "additionalProperties" => {}
          },
          {
            "name" => "Kugler D Adriana",
            "alternate" => [],
            "lastname" => "Kugler",
            "firstname" => "Adriana",
            "middlename" => "D",
            "role" => "author",
            "additionalProperties" => {}
          },
          {
            "name" => "Sacerdote  Bruce",
            "alternate" => [],
            "lastname" => "Sacerdote",
            "firstname" => "Bruce",
            "middlename" => "",
            "role" => "author",
            "additionalProperties" => {}
          }
        ],
        "etal" => false,
        "publisher" => "National Bureau of Economic Research",
        "pages" => "1-55",
        "publicationUrl" => "http://www.nber.org/papers/w15291",
        "publicationUrlLabel" => "web site",
        "publicationSource" => "Cambridge, MA",
        "series" => {
          "title" => "NBER Working Paper Series",
          "volume" => nil,
          "publisher" => nil,
          "number" => "15291",
          "publicationYear" => nil,
          "identifier" => [],
          "additionalProperties" => {}
        },
        "additionalProperties" => {},
        "last_updated" => "2016-05-09T15:24Z",
        "abstract" => "In 2005, hurricanes Katrina and Rita forced many children to relocate across the Southeast. While schools quickly enrolled evacuees, receiving families worried about the impact of evacuees on non-evacuee students. Data from Houston and Louisiana show that, on average, the influx of evacuees moderately reduced elementary math test scores in Houston. We reject linear-in-means models of peer effects and find evidence of a highly non-linear but monotonic model - student achievement improves with high ability and worsens with low ability peers. Moreover, exposure to undisciplined evacuees increased native absenteeism and disciplinary problems, supporting a \"bad apple\" model in behavior.\n\nDOI: 10.3386/w15291\n\nPublished: Scott A. Imberman & Adriana D. Kugler & Bruce I. Sacerdote, 2012. \"Katrina's Children: Evidence on the Structure of Peer Effects from Hurricane Evacuees,\" American Economic Review, American Economic Association, vol. 102(5), pages 2048-82, August.\n"
      }
    end
  end
end
