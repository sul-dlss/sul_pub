# frozen_string_literal: true

describe Clarivate::RestLinksClient, :vcr do
  subject(:links_client) { described_class.new }

  let(:ids) { %w[WOS:000081515000015 WOS:000346594100007 WOS:001061548400001 WOS:000000000000000] }
  let(:fields) { %w[doi pmid] }

  describe '#links' do
    let(:links) { links_client.links(ids, fields:) }

    it 'returns links' do
      expect(links).to eq(
        {
          'WOS:000346594100007' => {
            'doi' => '10.1002/2013GB004790'
          },
          'WOS:000081515000015' =>
            {
              'pmid' => '10435530'
            },
          'WOS:001061548400001' =>
            {
              'doi' => '10.1038/s41387-023-00244-4',
              'pmid' => '37689792'
            },
          'WOS:000000000000000' => {}
        }
      )
    end

    context 'when ids not prefixed' do
      let(:ids) { %w[000081515000015 000346594100007] }

      it 'raises ArgumentError' do
        expect { links }.to raise_error ArgumentError
      end
    end
  end
end
