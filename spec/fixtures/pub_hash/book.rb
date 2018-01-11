##
# These fixtures are used for mapping a pub_hash document into a CSL document,see
#
module PubHash
  module Book
    def book_pub_hash
      { title: 'My test title',
        type: 'book',
        author: [
          { name: 'Jones, P. L.' },
          { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
        year: '1987',
        publisher: 'Smith Books',
        booktitle: 'The Giant Book of Giant Ideas'
      }
    end

    def book_with_editors_pub_hash
      book_pub_hash.merge(author: [{ name: 'Smith, Jack', role: 'editor' },
                                   { name: 'Sprat, Jill', role: 'editor' },
                                   { name: 'Jones, P. L.' },
                                   { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }]
                         )
    end

    def book_series_pub_hash
      book_with_editors_pub_hash.reject { |k, _v| k == :booktitle }.merge(
        series: { title: 'The book series for Big Ideas', volume: 1, number: 4, year: 1933 }
      )
    end

  end
end
