# frozen_string_literal: true

describe Orcid::PubIdentifierMapper do
  describe '#map' do
    let(:ids) { described_class.map(pub_hash) }

    context 'pub identifier' do
      let(:pub_hash) do
        {
          identifier: [
            {
              type: 'doi',
              id: '10.1093/mind/LIX.236.433',
              url: 'https://doi.org/10.1093%2Fmind%2FLIX.236.433'
            }
          ]
        }
      end

      it 'maps' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'doi',
                                             'external-id-value' => '10.1093/mind/LIX.236.433',
                                             'external-id-url' => 'https://doi.org/10.1093%2Fmind%2FLIX.236.433',
                                             'external-id-relationship' => 'self'
                                           }
                                         ])
      end
    end

    context 'journal identifier' do
      let(:pub_hash) do
        {
          journal: {
            identifier: [{ type: 'doi', id: '10.1093/mind/LIX.236.433' }]
          }
        }
      end

      it 'maps' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'doi',
                                             'external-id-value' => '10.1093/mind/LIX.236.433',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'part-of'
                                           }
                                         ])
      end
    end

    context 'conference identifier' do
      let(:pub_hash) do
        {
          conference: {
            identifier: [{ type: 'doi', id: '10.1093/mind/LIX.236.433' }]
          }
        }
      end

      it 'maps' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'doi',
                                             'external-id-value' => '10.1093/mind/LIX.236.433',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'part-of'
                                           }
                                         ])
      end
    end

    context 'series identifier' do
      let(:pub_hash) do
        {
          series: {
            identifier: [{ type: 'doi', id: '10.1093/mind/LIX.236.433' }]
          }
        }
      end

      it 'maps' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'doi',
                                             'external-id-value' => '10.1093/mind/LIX.236.433',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'part-of'
                                           }
                                         ])
      end
    end

    context 'when missing identifier' do
      let(:pub_hash) { {} }

      it 'raises' do
        expect { ids }.to raise_error('An identifier is required')
      end
    end

    context 'when missing identifier type' do
      let(:pub_hash) do
        {
          identifier: [
            {
              type: 'doi',
              id: '10.1093/mind/LIX.236.433'
            },
            {
              type: '',
              id: '000324929800081'
            }
          ]
        }
      end

      it 'skips' do
        expect(ids['external-id'].size).to eq(1)
      end
    end

    context 'when missing identifier value' do
      let(:pub_hash) do
        {
          identifier: [
            {
              type: 'doi',
              id: '10.1093/mind/LIX.236.433'
            },
            {
              type: 'WosUID',
              id: ''
            }
          ]
        }
      end

      it 'skips' do
        expect(ids['external-id'].size).to eq(1)
      end
    end

    context 'when unmappable identifier type' do
      let(:pub_hash) do
        {
          identifier: [
            {
              type: 'doi',
              id: '10.1093/mind/LIX.236.433'
            },
            {
              type: 'SULPubId',
              id: '123'
            }
          ]
        }
      end

      it 'skips' do
        expect(ids['external-id'].size).to eq(1)
      end
    end

    context 'when searchworks url' do
      let(:pub_hash) do
        {
          identifier: [
            {
              type: 'issn',
              id: '0009-2541',
              url: 'http://searchworks.stanford.edu/?search_field=advanced&number=0009-2541'
            }
          ]
        }
      end

      it 'ignores url' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'issn',
                                             'external-id-value' => '0009-2541',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'self'
                                           }
                                         ])
      end
    end

    context 'when dupe for self and part-of' do
      let(:pub_hash) do
        {
          type: 'journal',
          identifier: [
            {
              type: 'doi',
              id: '10.1093/mind/LIX.236.433',
              url: 'https://doi.org/10.1093%2Fmind%2FLIX.236.433'
            }
          ],
          journal: {
            identifier: [
              {
                type: 'doi',
                id: '10.1093/mind/LIX.236.433',
                url: 'https://doi.org/10.1093%2Fmind%2FLIX.236.433'
              }
            ]
          }
        }
      end

      it 'ignores part-of identifier' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'doi',
                                             'external-id-value' => '10.1093/mind/LIX.236.433',
                                             'external-id-url' => 'https://doi.org/10.1093%2Fmind%2FLIX.236.433',
                                             'external-id-relationship' => 'self'
                                           }
                                         ])
      end
    end

    context 'when ISSN dupe for self and part-of' do
      let(:pub_hash) do
        {
          type: 'journal',
          identifier: [
            {
              type: 'issn',
              id: '0009-2541'
            }
          ],
          journal: {
            identifier: [
              {
                type: 'issn',
                id: '0009-2541'
              }
            ]
          }
        }
      end

      it 'ignores self identifier' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'issn',
                                             'external-id-value' => '0009-2541',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'part-of'
                                           }
                                         ])
      end
    end
  end
end
