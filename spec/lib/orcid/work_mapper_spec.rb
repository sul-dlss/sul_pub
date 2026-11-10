# frozen_string_literal: true

describe Orcid::WorkMapper do
  describe '#map' do
    let(:pub_hash) { described_class.map(work) }

    let(:work) { Orcid::WorkRecord.new(work_response) }

    let(:base_work_response) do
      {
        type: 'journal-article',
        title: {
          title: {
            value: 'Elephants Don\'t Play Chess'
          }
        },
        source: {
          'source-name': {
            value: 'Crossref'
          }
        },
        'external-ids': {
          'external-id': [
            {
              'external-id-value': '10.1016/S0921-8890(05)80025-9',
              'external-id-type': 'doi',
              'external-id-relationship': 'self',
              'external-id-url': {
                value: 'https://doi.org/10.1016/S0921-8890(05)80025-9'
              }
            },
            {
              'external-id-value': '0921-8890',
              'external-id-type': 'issn',
              'external-id-relationship': 'part-of'
            }
          ]
        },
        'short-description': 'In this paper we argue that classical AI is fundamentally flawed.',
        'publication-date': {
          year: { value: '1990' },
          month: { value: '03' },
          day: { value: '15' }
        },
        citation: {
          'citation-type': 'bibtex',
          'citation-value': %{@article{BROOKS19903,
title = {Elephants don't play chess},
journal = {Robotics and Autonomous Systems},
volume = {6},
issue = {1},
pages = {3-15},
year = {1990},
note = {Designing Autonomous Agents},
issn = {0921-8890},
doi = {https://doi.org/10.1016/S0921-8890(05)80025-9},
url = {https://www.sciencedirect.com/science/article/pii/S0921889005800259},
author = {Rodney A. Brooks},
publisher = {Elsevier}
}}
        },
        contributors: {
          contributor: [
            {
              'contributor-orcid': nil,
              'credit-name': {
                value: 'Rodney A. Brooks'
              },
              'contributor-email': nil,
              'contributor-attributes': {
                'contributor-sequence': nil,
                'contributor-role': 'author'
              }
            }
          ]
        },
        'journal-title': {
          value: 'Robotics and Autonomous Systems'
        }
      }
    end

    let(:work_response) { base_work_response }

    it 'is valid' do
      expect(PubHashValidator.valid?(pub_hash)).to be true
    end

    it 'maps type' do
      expect(pub_hash[:type]).to eq('article')
    end

    it 'maps work source' do
      expect(pub_hash[:orcid_work_source]).to eq('Crossref')
    end

    it 'maps provenance' do
      expect(pub_hash[:provenance]).to eq('orcid')
    end

    it 'maps title' do
      expect(pub_hash[:title]).to eq('Elephants Don\'t Play Chess')
    end

    it 'maps identifiers' do
      expect(pub_hash[:identifier].size).to eq(1)
      expect(pub_hash[:identifier].first).to eq({
                                                  type: 'doi',
                                                  id: '10.1016/S0921-8890(05)80025-9',
                                                  url: 'https://doi.org/10.1016/S0921-8890(05)80025-9'
                                                })
      expect(pub_hash[:doi]).to eq('10.1016/S0921-8890(05)80025-9')
    end

    it 'maps abstract' do
      expect(pub_hash[:abstract]).to eq('In this paper we argue that classical AI is fundamentally flawed.')
    end

    it 'maps year and date' do
      expect(pub_hash[:year]).to eq('1990')
      expect(pub_hash[:date]).to eq('1990-03-15T00:00:00')
    end

    it 'maps citations' do
      expect(pub_hash[:mla_citation]).to eq('Brooks, Rodney A. “Elephants Don\'t Play Chess.” <i>Robotics and Autonomous Systems</i> 6.1 (1990): 3–15. Web.')
      expect(pub_hash[:apa_citation]).to eq('Brooks, R. A. (1990). Elephants don\'t play chess. <i>Robotics and Autonomous Systems</i>, <i>6</i>(1), 3–15. https://doi.org/https://doi.org/10.1016/S0921-8890(05)80025-9')
      expect(pub_hash[:chicago_citation]).to eq('Brooks, Rodney A. 1990. “Elephants Don\'t Play Chess.” <i>Robotics and Autonomous Systems</i> 6 (1). Elsevier: 3–15. doi:https://doi.org/10.1016/S0921-8890(05)80025-9.')
    end

    it 'maps authors' do
      expect(pub_hash[:author].size).to eq(1)
      expect(pub_hash[:author].first).to eq({
                                              name: 'Rodney A. Brooks',
                                              role: 'author'
                                            })
    end

    it 'maps journal' do
      expect(pub_hash[:journal]).to eq({
                                         name: 'Robotics and Autonomous Systems',
                                         identifier: [
                                           {
                                             id: '0921-8890',
                                             type: 'issn'
                                           }
                                         ],
                                         volume: '6',
                                         issue: '1'
                                       })
    end

    it 'maps pages' do
      expect(pub_hash[:pages]).to eq('3–15')
    end

    it 'maps publisher' do
      expect(pub_hash[:publisher]).to eq('Elsevier')
    end

    context 'when no contributors' do
      let(:work_response) do
        base_work_response.dup.tap do |work_response|
          work_response[:contributors][:contributor] = []
          work_response[:citation][:'citation-value'] = %(@article{BROOKS19903,
title = {Fast, Cheap and Out of Control: A Robot Invasion of the Solar System},
author = {Rodney Allen Brooks and A. M. Flynn},
})
        end
      end

      it 'uses authors from BibTex' do
        expect(pub_hash[:author].size).to eq(2)
        expect(pub_hash[:author][1]).to eq({
                                             name: 'A. M. Flynn',
                                             role: 'author'
                                           })
      end
    end

    context 'when incomplete publication date' do
      let(:work_response) do
        base_work_response.dup.tap do |work_response|
          work_response[:'publication-date'][:day] = nil
        end
      end

      it 'only maps years' do
        expect(pub_hash[:year]).to eq('1990')
        expect(pub_hash[:date]).to be_nil
      end
    end

    context 'when a book' do
      let(:work_response) do
        {
          type: 'book',
          title: {
            title: {
              value: 'What Computers Can\'t Do'
            }
          },
          'external-ids': {
            'external-id': [
              {
                'external-id-value': '978-0-06-011082-6',
                'external-id-type': 'isbn',
                'external-id-relationship': 'self',
                'external-id-url': nil
              },
              {
                'external-id-value': '978-1-55860-363-9',
                'external-id-type': 'isbn',
                'external-id-relationship': 'part-of',
                'external-id-url': nil
              }
            ]
          },
          contributors: {
            contributor: [
              {
                'contributor-orcid': nil,
                'credit-name': {
                  value: 'Hubert Dreyfus'
                },
                'contributor-email': nil,
                'contributor-attributes': {
                  'contributor-sequence': nil,
                  'contributor-role': 'author'
                }
              }
            ]
          },
          'journal-title': {
            value: 'Topics in AI'
          },
          citation: {
            'citation-type': 'bibtex',
            'citation-value': %(@book{DREYFUS19903,
title = {What computers can't do},
volume = {6},
author = {Hubert Dreyfus},
})
          }
        }
      end

      it 'maps booktitle' do
        expect(pub_hash[:booktitle]).to eq('What Computers Can\'t Do')
        expect(pub_hash[:title]).to eq('What Computers Can\'t Do')
      end

      it 'maps series' do
        expect(pub_hash[:series][:name]).to eq('Topics in AI')
        expect(pub_hash[:series][:identifier]).to eq([{ type: 'isbn', id: '978-1-55860-363-9' }])
        expect(pub_hash[:series][:volume]).to eq('6')
      end
    end

    context 'when a conference paper' do
      let(:work_response) do
        {
          type: 'conference-paper',
          title: {
            title: {
              value: 'Turing test considered harmful'
            }
          },
          'external-ids': {
            'external-id': [
              {
                'external-id-value': '679-0-06-011082-6',
                'external-id-type': 'isbn',
                'external-id-relationship': 'self',
                'external-id-url': nil
              },
              {
                'external-id-value': '978-1-55860-363-9',
                'external-id-type': 'isbn',
                'external-id-relationship': 'part-of',
                'external-id-url': nil
              }
            ]
          },
          'journal-title': {
            value: 'Fourteenth International Joint Conference on Artificial Intelligence'
          }
        }
      end

      it 'maps conference name' do
        expect(pub_hash[:conference][:name]).to eq('Fourteenth International Joint Conference on Artificial Intelligence')
        expect(pub_hash[:conference][:identifier]).to eq([{ type: 'isbn', id: '978-1-55860-363-9' }])
      end
    end
  end
end
