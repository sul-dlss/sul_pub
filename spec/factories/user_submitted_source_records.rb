# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_submitted_source_record do
    source_data 'MyText'
    pmid 1
    lock_version 1
    source_fingerprint 'MyString'
    is_active false
    title 'MyString'
    year 1
  end

  factory :working_paper, parent: :user_submitted_source_record do
    pmid nil
    lock_version 0
    source_fingerprint 'c5af65af03161abf42b1c5ac0fbb7c9301a7ff44f06883340a7e732da2f3585b'
    year 2016
    is_active true
    source_data '{
      "identifier": [],
      "title": "This is Peter\'s Working Paper on the Revs Digital Library",
      "authorship": [
        {
          "sul_author_id": null,
          "cap_profile_id": 35324,
          "featured": false,
          "status": "APPROVED",
          "visibility": "PUBLIC",
          "additionalProperties": {}
        }
      ],
      "year": "2016",
      "abstract_restricted": "This is the abstract.",
      "type": "workingPaper",
      "provenance": "CAP",
      "allAuthors": "",
      "author": [
        {
          "name": "Mangiafico A Peter",
          "alternate": [],
          "lastname": "Mangiafico",
          "firstname": "Peter",
          "middlename": "A",
          "role": "author",
          "additionalProperties": {}
        }
      ],
      "etal": false,
      "publisher": "Stanford University",
      "pages": "5",
      "publicationUrl": "http://revslib.stanford.edu",
      "publicationUrlLabel": "Revs Digital Library",
      "publicationSource": "Stanford, CA",
      "series": {
        "title": "Series Name",
        "volume": null,
        "publisher": null,
        "number": "Series Number",
        "publicationYear": null,
        "identifier": [],
        "additionalProperties": {}
      },
      "additionalProperties": {},
      "last_updated": "2016-05-09T14:57Z",
      "abstract": "This is the abstract."
    }'
  end

  factory :case_study, parent: :user_submitted_source_record do
    pmid nil
    lock_version 0
    source_fingerprint '1ec894dd16404bda10ef7de8abd8f538c6c23814bb3a27f64b381b303b15fbc4'
    year 2016
    is_active true
    source_data '{
      "identifier": [
        {
          "id": "388525",
          "type": "SULPubId",
          "url": null,
          "additionalProperties": {}
        }
      ],
      "title": "Test Case Study 5-10-2016",
      "authorship": [
        {
          "sul_author_id": null,
          "cap_profile_id": 39042,
          "featured": true,
          "status": "APPROVED",
          "visibility": "PUBLIC",
          "additionalProperties": {}
        }
      ],
      "year": "2016",
      "abstract_restricted": "This is the case study abstract.",
      "type": "caseStudy",
      "provenance": "CAP",
      "allAuthors": "Other authors",
      "author": [
        {
          "name": "Author  First",
          "alternate": [],
          "lastname": "Author",
          "firstname": "First",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        },
        {
          "name": "Writer  Second ",
          "alternate": [],
          "lastname": "Writer",
          "firstname": "Second ",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        }
      ],
      "etal": true,
      "publisher": "Stanford University School of Business",
      "pages": "30-55",
      "publicationUrl": "https://www.google.com",
      "publicationUrlLabel": "Study 5-10 Link",
      "publicationSource": "Stanford, CA",
      "series": {
        "title": "Test Series name",
        "volume": null,
        "publisher": null,
        "number": "100",
        "publicationYear": null,
        "identifier": [],
        "additionalProperties": {}
      },
      "additionalProperties": {},
      "last_updated": "2016-05-10T11:39Z",
      "abstract": "This is the case study abstract."
    }'
  end

  factory :technical_report, parent: :user_submitted_source_record do
    pmid nil
    lock_version 0
    source_fingerprint '69c6230ab5303c27b84b31964276eb7f8cd43bac45bf3a519eb2f9f0fe09420b'
    year 2016
    is_active true
    source_data '{
      "identifier": [
        {
          "id": "388526",
          "type": "SULPubId",
          "url": null,
          "additionalProperties": {}
        }
      ],
      "title": "New Tech Report 5-10-16",
      "authorship": [
        {
          "sul_author_id": null,
          "cap_profile_id": 39042,
          "featured": true,
          "status": "APPROVED",
          "visibility": "PUBLIC",
          "additionalProperties": {}
        }
      ],
      "year": "2016",
      "abstract_restricted": "Tech Report abstract for 5-10-2016.",
      "type": "technicalReport",
      "provenance": "CAP",
      "allAuthors": "Other authors listed here",
      "author": [
        {
          "name": "Author  First",
          "alternate": [],
          "lastname": "Author",
          "firstname": "First",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        },
        {
          "name": "Writer  Second",
          "alternate": [],
          "lastname": "Writer",
          "firstname": "Second",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        }
      ],
      "etal": true,
      "publisher": "Stanford School of Engineering",
      "pages": "30-45",
      "publicationUrl": "https://www.google.com",
      "publicationUrlLabel": "Tech Report Link",
      "publicationSource": "Stanford, CA",
      "series": {
        "title": "Tech Report Series 5-10",
        "volume": null,
        "publisher": null,
        "number": "200",
        "publicationYear": null,
        "identifier": [],
        "additionalProperties": {}
      },
      "additionalProperties": {},
      "last_updated": "2016-05-10T11:38Z",
      "abstract": "Tech Report abstract for 5-10-2016."
    }'
  end

  factory :other_paper, parent: :user_submitted_source_record do
    pmid nil
    lock_version 0
    source_fingerprint '7267e0aa0c870a85599b681ccf1745ebdf6ff5e2bd20011c64f194b26ca68a8a'
    year 2007
    is_active true
    source_data '{
      "identifier": [],
      "title": "other paper - only mandatory fields",
      "authorship": [
        {
          "sul_author_id": null,
          "cap_profile_id": 26421,
          "featured": false,
          "status": "APPROVED",
          "visibility": "PUBLIC",
          "additionalProperties": {}
        }
      ],
      "year": "2007",
      "type": "otherPaper",
      "provenance": "CAP",
      "allAuthors": "",
      "author": [
        {
          "name": "Jayanthilal P Amith",
          "alternate": [],
          "lastname": "Jayanthilal",
          "firstname": "Amith",
          "middlename": "P",
          "role": "author",
          "additionalProperties": {}
        }
      ],
      "etal": false,
      "publisher": "NYC Publishers",
      "pages": "",
      "publicationUrl": "",
      "publicationUrlLabel": "",
      "publicationSource": "",
      "series": {
        "title": "",
        "volume": null,
        "publisher": null,
        "number": "",
        "publicationYear": null,
        "identifier": [],
        "additionalProperties": {}
      },
      "additionalProperties": {},
      "last_updated": "2016-03-25T13:22Z",
      "abstract": ""
    }'
  end
end
