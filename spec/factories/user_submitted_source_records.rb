# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_submitted_source_record do
    pmid nil
    publication_id 1234
    author_id nil
    lock_version 0
    source_fingerprint '62b1ebd89a6269eaeb04b7cc9f4502b4dd3e1faf8d984633234c8efba82c1ad4'
    is_active true
    title 'An improved TSVD-based Levenberg-Marquardt algorithm for history matching and comparison with Gauss-Newton'
    year 2016
    source_data '{
      "identifier": [
        {
          "id": "10.1016/j.petrol.2016.02.026",
          "type": "doi",
          "url": "http://dx.doi.org/10.1016/j.petrol.2016.02.026",
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
    source_fingerprint 'a1a086ffb168f962cb64e9fb44fe579abae97a4d2ca0cfe70151f411d1d0d707'
    year 2016
    is_active true
    source_data '{
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

  factory :technical_report, parent: :user_submitted_source_record do
    pmid nil
    lock_version 0
    source_fingerprint 'e07b9d34334e46de5ea8bfd5ab5c9e5786285316937c090b8b06c50962329b5f'
    year 2016
    is_active true
    source_data '{
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

  factory :other_paper, parent: :user_submitted_source_record do
    pmid nil
    lock_version 0
    source_fingerprint '31e19a12ddcbfe7f844b683170cba2e9bccb20be7dc7a606585670fa93f8412b'
    year 2016
    is_active true
    source_data '{
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
