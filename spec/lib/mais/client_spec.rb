# frozen_string_literal: true

describe Mais::Client do
  let(:subject) { described_class.new }

  describe '#fetch_orcid_users' do
    let(:orcid_users) { subject.fetch_orcid_users(limit: 5, page_size: 2) }

    it 'retrieves users' do
      VCR.use_cassette('Mais_Client/_fetch_orcid_users/retrieves users') do
        expect(orcid_users.size).to eq(5)
        expect(orcid_users.first).to eq(Mais::Client::OrcidUser.new('nataliex', 'https://sandbox.orcid.org/0000-0001-7161-0000', ['/read-limited'],
                                                                    '145d175c-1ac5-4ea7-935d-fg6d61ffb9a3'))
      end
    end

    context 'when server returns 500' do
      it 'raises' do
        VCR.use_cassette('Mais_Client/_fetch_orcid_users/raises') do
          expect { orcid_users }.to raise_error('UIT MAIS ORCID User API returned 500')
        end
      end
    end
  end
end
