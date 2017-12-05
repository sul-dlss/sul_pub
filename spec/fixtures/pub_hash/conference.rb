##
# These fixtures are used for mapping a pub_hash document into a CSL document
#
module PubHash
  module Conference
    def conference_pub_in_journal_hash
      { title: 'My test title',
        type: 'paper-conference',
        articlenumber: 33,
        pages: '33-56',
        author: [{ name: 'Smith, Jack', role: 'editor' },
                 { name: 'Sprat, Jill', role: 'editor' },
                 { name: 'Jones, P. L.' },
                 { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
        year: '1987',
        supplement: '33',
        publisher: 'Some Publisher',
        journal: { name: 'Some Journal Name', volume: 33, issue: 32, year: 1999 },
        conference: { name: 'The Big Conference', year: 2345, number: 33, location: 'Knoxville, TN', city: 'Knoxville', statecountry: 'TN' }
      }
    end

    def conference_pub_in_book_hash
      conference_pub_in_journal_hash.reject { |k, _v| [:journal, :supplement].include?(k) }.merge(booktitle: 'The Giant Book of Giant Ideas')
    end

    def conference_pub_in_series_hash
      conference_pub_in_book_hash.merge(
        publisher: 'Smith Books',
        series: { title: 'The book series for kings and queens', volume: 1, number: 4, year: 1933 }
      )
    end
  end
end
