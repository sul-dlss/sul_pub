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
        'short-description': 'In this paper we argue that classical AI is fundamentally flawed.'
      }
    end

    let(:work_response) { base_work_response }

    it 'is valid' do
      expect(PubHashValidator.valid?(pub_hash)).to be true
    end

    it 'maps type' do
      expect(pub_hash[:type]).to eq('article')
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
    end

    it 'maps abstract' do
      expect(pub_hash[:abstract]).to eq('In this paper we argue that classical AI is fundamentally flawed.')
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
  end
end
