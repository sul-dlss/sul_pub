# frozen_string_literal: true

describe Orcid::PubIdentifierMapper do
  describe '#map' do
    let(:ids) { described_class.map(pub_hash) }

    let(:base_pub_hash) do
      {
        identifier: [
          {
            type: 'doi',
            id: '10.1093/mind/LIX.236.433',
            url: 'https://doi.org/10.1093%2Fmind%2FLIX.236.433'
          },
          nil
        ]
      }
    end

    context 'pub identifier' do
      let(:pub_hash) { base_pub_hash }

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
        base_pub_hash.dup.merge(
          journal: {
            identifier: [{ type: 'doi', id: '11.1093/mind/LIX.236.433' }]
          }
        )
      end

      it 'maps' do
        expect(ids['external-id']).to include(
          {
            'external-id-type' => 'doi',
            'external-id-value' => '11.1093/mind/LIX.236.433',
            'external-id-url' => nil,
            'external-id-relationship' => 'part-of'
          }
        )
      end
    end

    context 'conference identifier' do
      let(:pub_hash) do
        base_pub_hash.dup.merge(
          conference: {
            identifier: [{ type: 'doi', id: '11.1093/mind/LIX.236.433' }]
          }
        )
      end

      it 'maps' do
        expect(ids['external-id']).to include(
          {
            'external-id-type' => 'doi',
            'external-id-value' => '11.1093/mind/LIX.236.433',
            'external-id-url' => nil,
            'external-id-relationship' => 'part-of'
          }
        )
      end
    end

    context 'series identifier' do
      let(:pub_hash) do
        base_pub_hash.dup.merge(
          series: {
            identifier: [{ type: 'doi', id: '11.1093/mind/LIX.236.433' }]
          }
        )
      end

      it 'maps' do
        expect(ids['external-id']).to include(
          {
            'external-id-type' => 'doi',
            'external-id-value' => '11.1093/mind/LIX.236.433',
            'external-id-url' => nil,
            'external-id-relationship' => 'part-of'
          }
        )
      end
    end

    context 'when missing a self identifier' do
      let(:pub_hash) do
        {
          journal: {
            identifier: [{ type: 'doi', id: '11.1093/mind/LIX.236.433' }]
          }
        }
      end

      it 'raises' do
        expect { ids }.to raise_error('A self identifier is required')
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

    context 'when invalid url' do
      let(:pub_hash) do
        {
          identifier: [
            {
              type: 'doi',
              id: '10.2216/0031-8884(2005)',
              url: 'https://dx.doi.org/10.2216/0031-8884(2005)44[453:ACAOTN]2.0.CO;2'
            }
          ]
        }
      end

      it 'ignores url' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'doi',
                                             'external-id-value' => '10.2216/0031-8884(2005)',
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
              type: 'doi',
              id: '10.1093/mind/LIX.236.433'
            },
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

      it 'ignores self ISSN identifier' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'doi',
                                             'external-id-value' => '10.1093/mind/LIX.236.433',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'self'
                                           },
                                           {
                                             'external-id-type' => 'issn',
                                             'external-id-value' => '0009-2541',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'part-of'
                                           }
                                         ])
      end
    end

    context 'sciencewire DOI' do
      let(:pub_hash) do
        {
          provenance: 'sciencewire',
          journal: {
            identifier: [
              {
                type: 'doi',
                id: '10.1093/mind/LIX.236.433'
              }
            ]
          }
        }
      end

      it 'moves DOI to self' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'doi',
                                             'external-id-value' => '10.1093/mind/LIX.236.433',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'self'
                                           }
                                         ])
      end
    end

    context 'sciencewire provenance with a WosItemID' do
      let(:pub_hash) do
        {
          provenance: 'sciencewire',
          identifier: [
            {
              type: 'WoSItemID',
              id: 'A1976BT25700002'
            }
          ]
        }
      end

      it 'converts to a WoSUID' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'wosuid',
                                             'external-id-value' => 'WOS:A1976BT25700002',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'self'
                                           }
                                         ])
      end
    end

    context 'sciencewire provenance with a both a WosItemID and a WosUID' do
      let(:pub_hash) do
        {
          provenance: 'sciencewire',
          identifier: [
            {
              type: 'WoSItemID',
              id: 'A1976BT25700002'
            },
            {
              type: 'WoSUID',
              id: 'WOS:A1976BT25700002'
            }
          ]
        }
      end

      it 'does not duplicate the wosuid' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'wosuid',
                                             'external-id-value' => 'WOS:A1976BT25700002',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'self'
                                           }
                                         ])
      end
    end

    context 'wos provenance with a MEDLINE WosItemID' do
      let(:pub_hash) do
        {
          provenance: 'wos',
          identifier: [
            {
              type: 'WoSItemID',
              id: '123456'
            },
            {
              type: 'WosUID',
              id: 'MEDLINE:123456'
            }
          ]
        }
      end

      it 'ignores the WoSItemID and uses the existing WoSUID' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'wosuid',
                                             'external-id-value' => 'MEDLINE:123456',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'self'
                                           }
                                         ])
      end
    end

    context 'wos provenance with a WOS WosItemID' do
      let(:pub_hash) do
        {
          provenance: 'wos',
          identifier: [
            {
              type: 'WoSItemID',
              id: '123456'
            },
            {
              type: 'WosUID',
              id: 'WOS:123456'
            }
          ]
        }
      end

      it 'does not duplicate the wosuid' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'wosuid',
                                             'external-id-value' => 'WOS:123456',
                                             'external-id-url' => nil,
                                             'external-id-relationship' => 'self'
                                           }
                                         ])
      end
    end

    context 'when dupe' do
      let(:pub_hash) do
        {
          identifier: [
            {
              type: 'issn',
              id: '0009-2541',
              url: 'https://portal.issn.org/resource/ISSN/0018-9448'
            },
            {
              type: 'eissn',
              id: '0009-2541'
            }
          ]
        }
      end

      it 'dedupes' do
        expect(ids['external-id']).to eq([
                                           {
                                             'external-id-type' => 'issn',
                                             'external-id-value' => '0009-2541',
                                             'external-id-url' => 'https://portal.issn.org/resource/ISSN/0018-9448',
                                             'external-id-relationship' => 'self'
                                           }
                                         ])
      end
    end
  end
end
