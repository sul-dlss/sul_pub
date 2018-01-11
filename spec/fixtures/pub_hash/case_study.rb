##
# These fixtures are used for mapping a pub_hash document into a CSL document,see
#
module PubHash
  module CaseStudy
    def case_study_pub_hash
      {
        title: 'HCL Technologies',
        type: 'caseStudy',
        provenance: 'CAP',
        author: [
          {
            name: 'Hill  Linda',
            lastname: 'Hill',
            firstname: 'Linda',
            middlename: '',
            alternate: [],
            role: 'author',
            additionalProperties: {}
          },
          {
            name: 'Khanna  Tarun',
            lastname: 'Khanna',
            firstname: 'Tarun',
            middlename: '',
            alternate: [],
            role: 'author',
            additionalProperties: {}
          },
          {
            name: 'Stecker A Emily',
            lastname: 'Stecker',
            firstname: 'Emily',
            middlename: 'A',
            alternate: [],
            role: 'author',
            additionalProperties: {}
          }
        ],
        year: '2008',
        publisher: 'Harvard Business Publishing',
        publicationSource: 'Boston'
      }
    end
  end
end
