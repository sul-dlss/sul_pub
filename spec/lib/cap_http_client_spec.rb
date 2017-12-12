
describe CapHttpClient do
  let(:token) { 'cool token' }
  let(:request_path) do
    %r{//
      #{Settings.CAP.TOKEN_USER}:#{Settings.CAP.TOKEN_PASS}@ #basic auth
      #{Settings.CAP.TOKEN_URI}:443.*
    }x
  end
  describe '#generate_token' do
    it 'sends post request and parse the response' do
      pending 'removal of the old cap_http_client code'
      stub_request(:post, request_path)
        .to_return(body: { access_token: token }.to_json)
      expect(subject.generate_token).to eq token
    end
    it 'on general StandardError' do
      stub_request(:post, request_path)
        .to_raise(StandardError)
      expect(NotificationManager).to receive(:error)
      expect { subject.generate_token }.to raise_error StandardError
    end
  end
  describe '#get_batch_from_cap_api' do
    it 'creates a request_path for a cap request' do
      stub_request(:post, request_path)
        .to_return(body: { access_token: token }.to_json)
      expect(subject).to receive(:make_cap_request)
        .with("#{Settings.CAP.AUTHORSHIP_API_PATH}?p=100&ps=10&since=2012-10-01")
      subject.get_batch_from_cap_api(100, 10, '2012-10-01')
    end
  end
  describe '#get_auth_profile' do
    it 'creates a request_path for a cap request' do
      stub_request(:post, request_path)
        .to_return(body: { access_token: token }.to_json)
      expect(subject).to receive(:make_cap_request)
        .with("#{Settings.CAP.AUTHORSHIP_API_PATH}/12")
      subject.get_auth_profile(12)
    end
  end
  describe '#get_cap_profile_by_sunetid' do
    it 'creates a request_path for a cap request' do
      stub_request(:post, request_path)
        .to_return(body: { access_token: token }.to_json)
      expect(subject).to receive(:make_cap_request)
        .with("#{Settings.CAP.AUTHORSHIP_API_PATH}?uids=12")
      subject.get_cap_profile_by_sunetid(12)
    end
  end
end
