# frozen_string_literal: true

describe Cap::Client, :vcr do
  subject(:cap_client) { described_class.new }

  let(:cap_profile_id) { 9_957 }

  before do
    null_logger = Logger.new(File::NULL)
    allow(NotificationManager).to receive(:cap_logger).and_return(null_logger)
  end

  describe '#working?' do
    it 'returns true when it can fetch author data' do
      expect(described_class.working?).to be true
    end
  end

  describe '#get_batch_from_cap_api' do
    let(:page) { 1 }
    let(:page_size) { 1 }

    it 'returns an author data Hash' do
      response = cap_client.get_batch_from_cap_api(page, page_size)
      expect(response).to be_an Hash
    end

    it 'retrieves pages of author data' do
      response = cap_client.get_batch_from_cap_api(page, page_size)
      expect(response['totalPages']).to be > 1
    end

    it 'retrieves pages of author data since date' do
      # To keep the specs the same so they can use a VCR recording, the requested
      # timestamp must be a fixed value.  To update it, remove the VCR recordings
      # and calculate a new timestamp value using:
      # timestamp = (Time.zone.now - 356.days).iso8601(3)
      timestamp = '2017-06-06T21:16:17.784Z'
      response = cap_client.get_batch_from_cap_api(page, page_size, timestamp)
      expect(response['totalPages']).to be > 1
    end
  end

  describe '#get_auth_profile' do
    it 'creates request params for a cap request' do
      response = cap_client.get_auth_profile(cap_profile_id)
      expect(response['profileId']).to eq cap_profile_id
    end
  end

  describe 'errors' do
    it 'logs and raises errors' do
      WebMock.stub_request(:get, /#{Settings.CAP.AUTHORSHIP_API_URI}/)
             .to_raise(StandardError)
      expect(NotificationManager).to receive(:error).once
      expect { cap_client.get_auth_profile(cap_profile_id) }.to raise_error StandardError
    end

    it 'logs and raises timeout errors' do
      WebMock.stub_request(:get, /#{Settings.CAP.AUTHORSHIP_API_URI}/)
             .to_raise(Faraday::TimeoutError)
      expect(NotificationManager).to receive(:error).once
      expect { cap_client.get_auth_profile(cap_profile_id) }.to raise_error Faraday::TimeoutError
    end
  end

  ##
  # PRIVATE

  describe '#access_token' do
    it 'sends authentication request and parses the response' do
      auth_token = 'cool token'
      WebMock.stub_request(:get, /#{Settings.CAP.TOKEN_URI}/)
             .to_return(status: 200, body: { access_token: auth_token }.to_json)
      expect(cap_client.send(:access_token)).to include(auth_token)
    end
  end

  describe '#authenticate' do
    it 'uses an access_token to authenticate' do
      auth_token = 'cool token'
      allow(cap_client).to receive(:access_token).and_return(auth_token)
      expect(cap_client.send(:authenticate)).to include(auth_token)
    end
  end
end
