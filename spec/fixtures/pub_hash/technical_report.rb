##
# These fixtures are used for mapping a pub_hash document into a CSL document,see
#
module PubHash
  module TechnicalReport
    def technical_report_online_pub_hash
      {
        title: 'Laws of Attrition: Crackdown on Russia’s Civil Society After Putin’s Return to the Presidency',
        type: 'technicalReport',
        provenance: 'CAP',
        pages: '',
        author: [
          {
            name: 'Gorbunova Yulia',
            lastname: 'Gorbunova',
            firstname: 'Yulia',
            middlename: '',
            alternate: [],
            role: 'author',
            additionalProperties: {}
          }
        ],
        year: '2013',
        publisher: 'Human Rights Watch',
        publicationUrl: 'http://www.hrw.org/reports/2013/04/24/laws-attrition',
        publicationUrlLabel: '',
        publicationSource: 'New York'
      }
    end

    def technical_report_print_pub_hash
      h = technical_report_online_pub_hash
      h[:author] << {
        name: 'Baranov Konstantin',
        lastname: 'Baranov',
        firstname: 'Konstantin',
        middlename: '',
        alternate: [],
        role: 'author',
        additionalProperties: {}
      }
      h[:publicationUrl] = ''
      h.delete(:pages)
      h
    end
  end
end
