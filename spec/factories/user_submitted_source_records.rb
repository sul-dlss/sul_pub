# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :user_submitted_source_record do
    pmid { nil }
    publication_id { 1234 }
    author_id { nil }
    lock_version { 0 }
    source_fingerprint { '62b1ebd89a6269eaeb04b7cc9f4502b4dd3e1faf8d984633234c8efba82c1ad4' }
    is_active { true }
    title { 'An improved TSVD-based Levenberg-Marquardt algorithm for history matching and comparison with Gauss-Newton' }
    year { 2016 }
    source_data do
      '{
      "identifier": [
        {
          "id": "10.1016/j.petrol.2016.02.026",
          "type": "doi",
          "url": "https://doi.org/10.1016/j.petrol.2016.02.026",
          "additionalProperties": {}
        }
      ],
      "title": "An improved TSVD-based Levenberg-Marquardt algorithm for history matching and comparison with Gauss-Newton",
      "authorship": [
        {
          "sul_author_id": null,
          "cap_profile_id": 45516,
          "featured": false,
          "status": "APPROVED",
          "visibility": "PUBLIC",
          "additionalProperties": {}
        }
      ],
      "year": "2016",
      "type": "article",
      "provenance": "CAP",
      "mesh_headings": [],
      "journal": {
        "name": "Journal of Petroleum Science and Engineering",
        "volume": "",
        "issue": "",
        "articleNumber": "",
        "specialissue": false,
        "year": "2016",
        "pages": "",
        "supplement": "",
        "identifier": [],
        "additionalProperties": {},
        "number": ""
      },
      "allAuthors": "",
      "author": [
        {
          "name": "Shirangi G Mehrdad",
          "alternate": [],
          "lastname": "Shirangi",
          "firstname": "Mehrdad",
          "middlename": "G",
          "role": "author",
          "additionalProperties": {}
        },
        {
          "name": "Emerick A Alexandre",
          "alternate": [],
          "lastname": "Emerick",
          "firstname": "Alexandre",
          "middlename": "A",
          "role": "author",
          "additionalProperties": {}
        }
      ],
      "etal": false,
      "last_updated": "2016-03-02T12:59Z",
      "publisher": "",
      "additionalProperties": {}
    }'
    end
  end

  factory :working_paper, parent: :user_submitted_source_record do
    pmid { nil }
    lock_version { 0 }
    source_fingerprint { 'c5af65af03161abf42b1c5ac0fbb7c9301a7ff44f06883340a7e732da2f3585b' }
    year { 2016 }
    is_active { true }
    source_data do
      '{
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
  end

  factory :case_study, parent: :user_submitted_source_record do
    pmid { nil }
    lock_version { 0 }
    source_fingerprint { 'a1a086ffb168f962cb64e9fb44fe579abae97a4d2ca0cfe70151f411d1d0d707' }
    year { 2016 }
    is_active { true }
    source_data do
      '{
      "identifier": [],
      "title": "This is Peter\'s Case Study on the Revs Digital Library",
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
      "type": "caseStudy",
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
      "pages": "1-5",
      "publicationUrl": "http://revslib.stanford.edu",
      "publicationUrlLabel": "Revs Digital Library",
      "publicationSource": "Stanford, CA",
      "series": {
        "title": "Series Name",
        "volume": null,
        "publisher": null,
        "number": "5",
        "publicationYear": null,
        "identifier": [],
        "additionalProperties": {}
      },
      "additionalProperties": {},
      "last_updated": "2016-05-17T11:47Z",
      "abstract": "This is the abstract."
    }
'
    end
  end

  factory :technical_report, parent: :user_submitted_source_record do
    pmid { nil }
    lock_version { 0 }
    source_fingerprint { 'e07b9d34334e46de5ea8bfd5ab5c9e5786285316937c090b8b06c50962329b5f' }
    year { 2016 }
    is_active { true }
    source_data do
      '{
      "identifier": [],
      "title": "This is Peter\'s Technical Report on the Revs Digital Library",
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
      "abstract_restricted": "This is the abstract for Peter\'s Technical Report on the Revs Digital Library",
      "type": "technicalReport",
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
      "pages": "1-5",
      "publicationUrl": "http://revslib.stanford.edu",
      "publicationUrlLabel": "Revs Digital Library",
      "publicationSource": "Stanford, CA ",
      "series": {
        "title": "Series Name",
        "volume": null,
        "publisher": null,
        "number": "5",
        "publicationYear": null,
        "identifier": [],
        "additionalProperties": {}
      },
      "additionalProperties": {},
      "last_updated": "2016-05-17T11:42Z",
      "abstract": "This is the abstract for Peter\'s Technical Report on the Revs Digital Library"
    }'
    end
  end

  factory :other_paper, parent: :user_submitted_source_record do
    pmid { nil }
    lock_version { 0 }
    source_fingerprint { '31e19a12ddcbfe7f844b683170cba2e9bccb20be7dc7a606585670fa93f8412b' }
    year { 2016 }
    is_active { true }
    source_data do
      '{
      "identifier": [],
      "title": "This is Peter\'s Other Paper on the Revs Digital Library",
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
      "type": "otherPaper",
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
      "pages": "1-5",
      "publicationUrl": "http://revslib.stanford.edu",
      "publicationUrlLabel": "Revs Digital Library",
      "publicationSource": "Stanford, CA",
      "series": {
        "title": "Series Name",
        "volume": null,
        "publisher": null,
        "number": "5",
        "publicationYear": null,
        "identifier": [],
        "additionalProperties": {}
      },
      "additionalProperties": {},
      "last_updated": "2016-05-17T11:44Z",
      "abstract": "This is the abstract."
    }'
    end
  end
  factory :book, parent: :user_submitted_source_record do
    pmid { nil }
    lock_version { 0 }
    title { 'This is a book title' }
    source_fingerprint { 'dc3f425b85d483182e8b9f40c48a93b83cf6c065dc058ab4cd6b3787a9f017ff' }
    year { 2015 }
    is_active { true }
    source_data do
      '{
      "identifier": [
        {
          "id": "123456789",
          "type": "isbn",
          "url": null,
          "additionalProperties": {}
        }
      ],
      "title": "This is a book title",
      "authorship": [
        {
          "sul_author_id": null,
          "cap_profile_id": 62029,
          "featured": false,
          "status": "APPROVED",
          "visibility": "PUBLIC",
          "additionalProperties": {}
        }
      ],
      "year": "2015",
      "abstract_restricted": "This is an abstract for the book.",
      "type": "book",
      "provenance": "CAP",
      "allAuthors": "",
      "author": [
        {
          "name": "Reed J Phillip",
          "alternate": [],
          "lastname": "Reed",
          "firstname": "Phillip",
          "middlename": "J",
          "role": "author",
          "additionalProperties": {}
        },
        {
          "name": "Stanford  Jane",
          "alternate": [],
          "lastname": "Stanford",
          "firstname": "Jane",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        }
      ],
      "etal": false,
      "edition": "1",
      "publisher": "Stanford University Press",
      "pages": "",
      "series": {
        "title": "The Series Title",
        "volume": "3",
        "publisher": null,
        "number": "2",
        "publicationYear": null,
        "identifier": [],
        "additionalProperties": {}
      },
      "additionalProperties": {},
      "last_updated": "2016-05-23T11:47Z"
    }'
    end
  end
  factory :book_chapter, parent: :user_submitted_source_record do
    pmid { nil }
    lock_version { 0 }
    source_fingerprint { '3e858fd88a91c8441d37eb045aaab0e2e7811c2235214c0081add19635075606' }
    title { 'Geospatial Resource Discovery' }
    year { 2016 }
    is_active { true }
    source_data do
      '{
      "identifier": [
        {
          "id": "978-0-8389-1414-4",
          "type": "isbn",
          "url": null,
          "additionalProperties": {}
        }
      ],
      "title": "Geospatial Resource Discovery",
      "authorship": [
        {
          "sul_author_id": null,
          "cap_profile_id": 62029,
          "featured": false,
          "status": "APPROVED",
          "visibility": "PUBLIC",
          "additionalProperties": {}
        }
      ],
      "year": "2016",
      "abstract_restricted": "",
      "type": "inbook",
      "provenance": "CAP",
      "allAuthors": "",
      "author": [
        {
          "name": "Hardy  Darren",
          "alternate": [],
          "lastname": "Hardy",
          "firstname": "Darren",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        },
        {
          "name": "Reed  Jack",
          "alternate": [],
          "lastname": "Reed",
          "firstname": "Jack",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        },
        {
          "name": "Sadler  Bess",
          "alternate": [],
          "lastname": "Sadler",
          "firstname": "Bess",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        }
      ],
      "etal": false,
      "booktitle": "Exploring Discovery: The Front Door to Your Library\'s Licensed and Digitized Content",
      "edition": "",
      "publisher": "American Library Association Editions",
      "chapter": "5",
      "pages": "47-62",
      "series": {
        "title": null,
        "volume": null,
        "publisher": null,
        "number": null,
        "publicationYear": null,
        "identifier": [],
        "additionalProperties": {}
      },
      "additionalProperties": {},
      "last_updated": "2016-05-23T12:01Z"
    }'
    end
  end
  factory :conference_proceeding, parent: :user_submitted_source_record do
    pmid { nil }
    lock_version { 0 }
    source_fingerprint { 'fc74b1f712626c6f26d094d06408cfdcf1de013b956c7c837814bb87007707d3' }
    title { 'Preservation and discovery for GIS data' }
    year { 2015 }
    is_active { true }
    source_data do
      '{
      "identifier": [],
      "title": "Preservation and discovery for GIS data",
      "authorship": [
        {
          "sul_author_id": null,
          "cap_profile_id": 62029,
          "featured": false,
          "status": "APPROVED",
          "visibility": "PUBLIC",
          "additionalProperties": {}
        }
      ],
      "year": "2015",
      "abstract_restricted": "",
      "type": "inproceedings",
      "provenance": "CAP",
      "allAuthors": "",
      "author": [
        {
          "name": "Reed  Jack",
          "alternate": [],
          "lastname": "Reed",
          "firstname": "Jack",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        }
      ],
      "etal": false,
      "howpublished": "monograph",
      "pages": "",
      "publisher": "Esri",
      "articlenumber": "",
      "conference": {
        "name": "Esri User Conference",
        "location": "San Diego, California",
        "number": "",
        "organization": "",
        "year": "2015",
        "startdate": "July 20, 2015",
        "enddate": "July 24, 2015",
        "doi": "",
        "additionalProperties": {}
      },
      "additionalProperties": {}
    }'
    end
  end
  factory :conference_proceeding_without_event_year, parent: :user_submitted_source_record do
    pmid { nil }
    lock_version { 0 }
    source_fingerprint { 'fc74b1f712626c6f26d094d06408cfdcf1de013b956c7c837814bb87007707d3' }
    title { 'Preservation and discovery for GIS data' }
    year { 1997 }
    is_active { true }
    source_data do
      '{
      "identifier": [],
      "title": "Preservation and discovery for GIS data",
      "authorship": [
        {
          "sul_author_id": null,
          "cap_profile_id": 62029,
          "featured": false,
          "status": "APPROVED",
          "visibility": "PUBLIC",
          "additionalProperties": {}
        }
      ],
      "year": "1997",
      "abstract_restricted": "",
      "type": "inproceedings",
      "provenance": "CAP",
      "allAuthors": "",
      "author": [
        {
          "name": "Reed  Jack",
          "alternate": [],
          "lastname": "Reed",
          "firstname": "Jack",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        }
      ],
      "etal": false,
      "howpublished": "monograph",
      "pages": "",
      "publisher": "Esri",
      "articlenumber": "",
      "conference": {
        "name": "Esri User Conference",
        "location": "San Diego, California",
        "number": "",
        "organization": "",
        "startdate": "1997-06-02T00:00:00",
        "enddate": "1997-06-04T00:00:00",
        "doi": "",
        "additionalProperties": {}
      },
      "additionalProperties": {}
    }'
    end
  end
  factory :journal_article, parent: :user_submitted_source_record do
    pmid { nil }
    lock_version { 0 }
    source_fingerprint { '238f79e4f238069326122054ba149be4e0749a90f5330bcd1d5e504b581eeb75' }
    title { 'The Flat Rock Cemetery Mapping Project:  A Case Study in Community Archaeology' }
    year { 2012 }
    is_active { true }
    source_data do
      '{
      "identifier": [],
      "title": "The Flat Rock Cemetery Mapping Project:  A Case Study in Community Archaeology",
      "authorship": [
        {
          "sul_author_id": null,
          "cap_profile_id": 62029,
          "featured": false,
          "status": "APPROVED",
          "visibility": "PUBLIC",
          "additionalProperties": {}
        }
      ],
      "year": "2012",
      "abstract_restricted": "",
      "type": "article",
      "provenance": "CAP",
      "mesh_headings": [],
      "journal": {
        "name": "Early Georgia",
        "volume": "40",
        "issue": "1",
        "articleNumber": "",
        "specialissue": false,
        "year": "2012",
        "pages": "23-44",
        "supplement": "",
        "identifier": [],
        "additionalProperties": {},
        "number": "1"
      },
      "allAuthors": "",
      "author": [
        {
          "name": "Glover B Jeffrey",
          "alternate": [],
          "lastname": "Glover",
          "firstname": "Jeffrey",
          "middlename": "B",
          "role": "author",
          "additionalProperties": {}
        },
        {
          "name": "Woodard  Kelly",
          "alternate": [],
          "lastname": "Woodard",
          "firstname": "Kelly",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        },
        {
          "name": "Reed Jack P",
          "alternate": [],
          "lastname": "Reed",
          "firstname": "P",
          "middlename": "Jack",
          "role": "author",
          "additionalProperties": {}
        },
        {
          "name": "Waits  Johnny",
          "alternate": [],
          "lastname": "Waits",
          "firstname": "Johnny",
          "middlename": "",
          "role": "author",
          "additionalProperties": {}
        }
      ],
      "etal": false,
      "last_updated": "2016-05-23T14:03Z",
      "publisher": "The Society for Georgia Archaeology",
      "additionalProperties": {}
    }'
    end
  end
end
