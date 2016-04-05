FactoryGirl.define do
  factory :pub_hash do
    initialize_with do
      new(provenance: 'sciencewire',
          pmid: '15572175',
          sw_id: '6787731',
          title:         'New insights into the expression and function of neural connexins with transgenic mouse mutants',
          abstract_restricted:         'Gap junctions represent direct intercellular conduits between contacting cells. The subunit proteins of these conduits are called connexins. To date, 20 and 21 connexin genes have been described in the mouse and human genome, respectiv',
          author:         [{ name: 'Sohl,G,' },
                           { name: 'Odermatt,B,' },
                           { name: 'Maxeiner,S,' },
                           { name: 'Degen,J,' },
                           { name: 'Willecke,K,' },
                           { name: 'SecondLast,T,' },
                           { name: 'Last,O' }],
          year: '2004',
          date: '2004-12-01T00:00:00',
          authorcount: '6',
          documenttypes_sw: ['Article'],
          type: 'article',
          documentcategory_sw: 'Conference Proceeding Document',
          publicationimpactfactorlist_sw:         ['4.617,2004,ExactPublicationYear', '10.342,2011,MostRecentYear'],
          publicationcategoryrankinglist_sw:         ['28/198;NEUROSCIENCES;2004;SC;ExactPublicationYear',
                                                      '10/242;NEUROSCIENCES;2011;SC;MostRecentYear'],
          numberofreferences_sw: '159',
          timescited_sw_retricted: '40',
          timenotselfcited_sw: '30',
          authorcitationcountlist_sw: '1,2,38|2,0,40|3,3,37|4,0,40|5,10,30',
          rank_sw: '',
          ordinalrank_sw: '67',
          normalizedrank_sw: '',
          newpublicationid_sw: '',
          isobsolete_sw: 'false',
          publisher: 'ELSEVIER SCIENCE BV',
          city: 'AMSTERDAM',
          stateprovince: '',
          country: 'NETHERLANDS',
          pages: '245-259',
          issn: '0165-0173',
          journal:         { name: 'BRAIN RESEARCH REVIEWS',
                             volume: '47',
                             issue: '1-3',
                             pages: '245-259',
                             identifier:           [{ type: 'issn',
                                                      id: '0165-0173',
                                                      url: Settings.SULPUB_ID.SEARCHWORKS_URI + '0165-0173' },
                                                    { type: 'doi',
                                                      id: '10.1016/j.brainresrev.2004.05.006',
                                                      url: 'http://dx.doi.org/10.1016/j.brainresrev.2004.05.006' }] },
          abstract:         'Gap junctions represent direct intercellular conduits between contacting cells. The subunit proteins of these conduits are called connexins. To date, 20 and 21 connexin genes have been described in the mouse and human genome, respectiv',
          last_updated: '2013-07-23 22:06:49 UTC',
          authorship:         [{ cap_profile_id: 8804,
                                 sul_author_id: 2579,
                                 status: 'unknown',
                                 visibility: 'private',
                                 featured: false }])
    end
  end

  factory :et_al_pub_hash, parent: :pub_hash do
    initialize_with do
      new(provenance: 'sciencewire',
          pmid: '15572175',
          sw_id: '6787731',
          title:           'New insights into the expression and function of neural connexins with transgenic mouse mutants',
          abstract_restricted:           'Gap junctions represent direct intercellular conduits between contacting cells. The subunit proteins of these conduits are called connexins. To date, 20 and 21 connexin genes have been described in the mouse and human genome, respectiv',
          author:           [{ name: 'Sohl,G,' },
                             { name: 'Odermatt,B,' }],
          etal: true,
          year: '2004',
          date: '2004-12-01T00:00:00',
          authorcount: '6',
          documenttypes_sw: ['Article'],
          type: 'article',
          documentcategory_sw: 'Conference Proceeding Document',
          numberofreferences_sw: '159',
          publisher: 'ELSEVIER SCIENCE BV',
          city: 'AMSTERDAM',
          stateprovince: '',
          country: 'NETHERLANDS',
          pages: '245-259',
          issn: '0165-0173',
          journal:           { name: 'BRAIN RESEARCH REVIEWS',
                               volume: '47',
                               issue: '1-3',
                               pages: '245-259',
                               identifier:             [{ type: 'issn',
                                                          id: '0165-0173',
                                                          url: Settings.SULPUB_ID.SEARCHWORKS_URI + '0165-0173' },
                                                        { type: 'doi',
                                                          id: '10.1016/j.brainresrev.2004.05.006',
                                                          url: 'http://dx.doi.org/10.1016/j.brainresrev.2004.05.006' }] },
          abstract:           'Gap junctions represent direct intercellular conduits between contacting cells. The subunit proteins of these conduits are called connexins. To date, 20 and 21 connexin genes have been described in the mouse and human genome, respectiv',
          last_updated: '2013-07-23 22:06:49 UTC',
          authorship:           [{ cap_profile_id: 8804,
                                   sul_author_id: 2579,
                                   status: 'unknown',
                                   visibility: 'private',
                                   featured: false }])
    end
  end

  factory :conference_pub_in_journal, parent: :pub_hash do
    initialize_with do
      new(title: 'My test title',
          type: 'article-journal',
          articlenumber: 33,
          pages: '3-6',
          author: [{ name: 'Smith, Jack', role: 'editor' },
                   { name: 'Sprat, Jill', role: 'editor' },
                   { name: 'Jones, P. L.' },
                   { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
          year: '1987',
          supplement: '33',
          publisher: 'Some Publisher',
          journal: { name: 'Some Journal Name', volume: 33, issue: 32, year: 1999 },
          conference: { name: 'The Big Conference', year: 2345, number: 33, location: 'Knoxville, TN', city: 'Knoxville', statecountry: 'TN' })
    end
  end

  factory :conference_pub_in_book_hash, parent: :pub_hash do
    initialize_with do
      new(title: 'My test title',
          type: 'paper-conference',
          articlenumber: 33,
          pages: '33-56',
          author: [{ name: 'Smith, Jack', role: 'editor' },
                   { name: 'Sprat, Jill', role: 'editor' },
                   { name: 'Jones, P. L.' },
                   { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
          year: '1987',
          publisher: 'Smith Books',
          booktitle: 'The Giant Book of Giant Ideas',
          conference: { name: 'The Big Conference', year: 2345, number: 33, location: 'Knoxville, TN', city: 'Knoxville', statecountry: 'TN' })
    end
  end

  factory :conference_pub_in_series_hash, parent: :pub_hash do
    initialize_with do
      new(title: 'My test title',
          type: 'paper-conference',
          articlenumber: 33,
          pages: '33-56',
          author: [{ name: 'Smith, Jack', role: 'editor' },
                   { name: 'Sprat, Jill', role: 'editor' },
                   { name: 'Jones, P. L.' },
                   { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
          year: '1987',
          publisher: 'Smith Books',
          booktitle: 'The Giant Book of Giant Ideas',
          conference: { name: 'The Big Conference', year: 2345, number: 33, location: 'Knoxville, TN', city: 'Knoxville', statecountry: 'TN' },
          series: { title: 'The book series for kings and queens', volume: 1, number: 4, year: 1933 })
    end
  end

  factory :conference_pub_in_nothing_hash, parent: :pub_hash do
    initialize_with do
      new(title: 'My test title',
          type: 'speech',
          author: [
            { name: 'Jones, P. L.' },
            { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
          conference: { name: 'The Big Conference', year: '1999', number: 33, location: 'Knoxville, TN', city: 'Knoxville', statecountry: 'TN' }
         )
    end
  end

  factory :book_pub_hash, parent: :pub_hash do
    initialize_with do
      new(title: 'My test title',
          type: 'book',
          author: [
            { name: 'Jones, P. L.' },
            { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
          year: '1987',
          publisher: 'Smith Books',
          booktitle: 'The Giant Book of Giant Ideas')
    end
  end

  factory :book_pub_with_editors_hash, parent: :pub_hash do
    initialize_with do
      new(title: 'My test title',
          type: 'book',
          author: [{ name: 'Smith, Jack', role: 'editor' },
                   { name: 'Sprat, Jill', role: 'editor' }],
          year: '1987',
          publisher: 'Smith Books',
          booktitle: 'The Giant Book of Giant Ideas')
    end
  end

  factory :series_pub_hash, parent: :pub_hash do
    initialize_with do
      new(title: 'My test title',
          type: 'book',
          author: [{ name: 'Smith, Jack', role: 'editor' },
                   { name: 'Sprat, Jill', role: 'editor' },
                   { name: 'Jones, P. L.' },
                   { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
          year: '1987',
          publisher: 'Smith Books',
          booktitle: 'The Giant Book of Giant Ideas',
          series: { title: 'The book series for Big Ideas', volume: 1, number: 4, year: 1933 })
    end
  end

  factory :article_pub_hash, parent: :pub_hash do
    initialize_with do
      new(title: 'My test title',
          type: 'article',
          pages: '3-6',
          author: [{ name: 'Smith, Jack', role: 'editor' },
                   { name: 'Sprat, Jill', role: 'editor' },
                   { name: 'Jones, P. L.' },
                   { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
          year: '1987',
          publisher: 'Some Publisher',
          journal: { name: 'Some Journal Name', volume: 33, issue: 32, year: 1999 })
    end
  end
end
