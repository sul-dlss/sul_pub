# frozen_string_literal: true

describe Mais::Client do
  # NOTE: This spec uses vcr cassettes from the MAIS API that were edited to obscure access tokens.
  #   The 500 test is also hard to replicate since the API does not return 500s typically.
  #   If the cassettes are re-created, you need to edit the access tokens in the cassette files and in the expectations below.

  let(:subject) { described_class.new }

  describe '#fetch_orcid_users' do
    let(:orcid_users) { subject.fetch_orcid_users(limit: 5, page_size: 2) }

    it 'retrieves users' do
      VCR.use_cassette('Mais_Client/_fetch_orcid_users/retrieves users') do
        expect(orcid_users.size).to eq(5)
        expect(orcid_users.first).to eq(Mais::Client::OrcidUser.new('nataliex', 'https://sandbox.orcid.org/0000-0001-7161-1827', ['/read-limited'],
                                                                    'XXXXXXXX-1ac5-4ea7-835d-bc6d61ffb9a8'))
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

  describe '#fetch_orcid_user' do
    let(:orcid_user) { subject.fetch_orcid_user(sunetid: 'nataliex') }
    let(:bad_orcid_user) { subject.fetch_orcid_user(sunetid: 'totally-bogus') }

    it 'retrieves a single user' do
      VCR.use_cassette('Mais_Client/_fetch_orcid_user/retrieves user') do
        expect(orcid_user).to eq(Mais::Client::OrcidUser.new('nataliex', 'https://sandbox.orcid.org/0000-0001-7161-1827', ['/read-limited'],
                                                             'XXXXXXXX-1ac5-4ea7-835d-bc6d61ffb9a8'))
      end
    end

    context 'when a user is not found' do
      it 'returns nil' do
        VCR.use_cassette('Mais_Client/_fetch_orcid_user/raises') do
          expect(bad_orcid_user).to be_nil
        end
      end
    end
  end
end
