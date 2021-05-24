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
        'external-ids': {
          'external-id': [
            {
              'external-id-value': '10.1016/S0921-8890(05)80025-9',
              'external-id-type': 'doi',
              'external-id-relationship': 'self',
              'external-id-url': 'https://doi.org/10.1016/S0921-8890(05)80025-9'
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
          "citation-type": 'bibtex',
          "citation-value": %{@article{BROOKS19903,
title = {Elephants don't play chess},
journal = {Robotics and Autonomous Systems},
volume = {6},
number = {1},
pages = {3-15},
year = {1990},
note = {Designing Autonomous Agents},
issn = {0921-8890},
doi = {https://doi.org/10.1016/S0921-8890(05)80025-9},
url = {https://www.sciencedirect.com/science/article/pii/S0921889005800259},
author = {Rodney A. Brooks}
}}
        },
        contributors: {
          contributor: [
            {
              "contributor-orcid": nil,
              "credit-name": {
                value: 'Rodney A. Brooks'
              },
              "contributor-email": nil,
              "contributor-attributes": {
                "contributor-sequence": nil,
                "contributor-role": 'author'
              }
            }
          ]
        },
        "journal-title": {
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
      expect(pub_hash[:chicago_citation]).to eq('Brooks, Rodney A. 1990. “Elephants Don\'t Play Chess.” <i>Robotics and Autonomous Systems</i> 6 (1): 3–15. doi:https://doi.org/10.1016/S0921-8890(05)80025-9.')
    end

    it 'maps authors' do
      expect(pub_hash[:author].size).to eq(1)
      expect(pub_hash[:author].first).to eq({
                                              name: 'Rodney A. Brooks',
                                              role: 'author'
                                            })
    end

    it 'maps journal title' do
      expect(pub_hash[:journal]).to eq({
                                         name: 'Robotics and Autonomous Systems'
                                       })
    end

    context 'when id relationship is not self' do
      let(:work_response) do
        base_work_response.dup.tap do |work_response|
          work_response[:'external-ids'][:'external-id'].first[:'external-id-relationship'] = 'part-of'
        end
      end

      it 'ignores identifier' do
        expect(pub_hash[:identifier].size).to eq(0)
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
              }
            ]
          },
          contributors: {
            contributor: [
              {
                "contributor-orcid": nil,
                "credit-name": {
                  value: 'Hubert Dreyfus'
                },
                "contributor-email": nil,
                "contributor-attributes": {
                  "contributor-sequence": nil,
                  "contributor-role": 'author'
                }
              }
            ]
          }
        }
      end

      it 'maps booktitle' do
        expect(pub_hash[:booktitle]).to eq('What Computers Can\'t Do')
        expect(pub_hash[:title]).to eq('What Computers Can\'t Do')
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
      end
    end
  end
end
