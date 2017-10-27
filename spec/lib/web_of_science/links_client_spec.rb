describe WebOfScience::LinksClient do
  let(:ids) { %w(000081515000015 000346594100007) }
  let(:fields) { %w(ut doi pmid) }

  before do
    allow(Settings.WOS).to receive(:AUTH_CODE).and_return("YXR6OmZvb2Jhcg==\n") # atz:foobar
  end
  subject { described_class.new }

  describe '#initialize' do
    context 'with no params' do
      it 'has defaults, including auth from Settings' do
        expect(subject.host).to eq 'https://ws.isiknowledge.com'
        expect(subject.username).to eq 'atz'
        expect(subject.password).to eq 'foobar'
      end
    end
    context 'with params' do
      subject { described_class.new(username: 'leland', password: 'sunflower', host: 'http://proxy.us') }
      it 'accepts overrides' do
        expect(subject.host).to eq 'http://proxy.us'
        expect(subject.username).to eq 'leland'
        expect(subject.password).to eq 'sunflower'
      end
    end
  end

  describe '#links' do
    it 'requires param' do
      expect { subject.links }.to raise_error ArgumentError
    end

    context 'with param' do
      let(:response_xml) { File.read('spec/fixtures/wos_links/links_response.xml') }
      let(:links) { subject.links(ids, fields) }

      before do
        allow(subject.send(:connection)).to receive(:post).with(any_args).and_return(double(body: response_xml))
      end

      it 'returns matching identifiers' do
        expect(links).to match a_hash_including(*ids)
        expect(links[ids[0]]).to match a_hash_including('pmid' => '10435530', 'ut' => '000081515000015', 'doi' => '10.1118/1.598623')
        expect(links[ids[1]]).to match a_hash_including('ut' => '000346594100007', 'doi' => '10.1002/2013GB004790')
      end
    end
  end

  describe '#request_body' do
    let(:request_xml) { subject.send(:request_body, ids, fields) }

    it 'returns well formed XML' do
      expect { Nokogiri::XML(request_xml) { |config| config.strict.noblanks } }.not_to raise_error
    end
    it 'contains the ids' do
      expect(request_xml).to include ids.first
    end
    it 'contains the fields' do
      expect(request_xml).to include fields.first
    end
  end
end
