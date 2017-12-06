##
# These fixtures are used for mapping a pub_hash document into a CSL document,see
#
module PubHash
  module Article
    def article_pub_hash
      { title: 'My test title',
        type: 'article',
        pages: '3-6',
        author: [{ name: 'Smith, Jack', role: 'editor' },
                 { name: 'Sprat, Jill', role: 'editor' },
                 { name: 'Jones, P. L.' },
                 { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
        year: '1987',
        publisher: 'Some Publisher',
        journal: { name: 'Some Journal Name', volume: 33, issue: 32, year: 1999 }
      }
    end
  end
end
