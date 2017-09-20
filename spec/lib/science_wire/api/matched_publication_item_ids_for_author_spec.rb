SingleCov.covered!

describe ScienceWire::API::MatchedPublicationItemIdsForAuthor do
  include ItemResponses
  let(:client) do
    ScienceWire::Client.new(
      license_id: 'license', host: Settings.SCIENCEWIRE.HOST
    )
  end

  subject { described_class.new(client: client) }

  describe '#matched_publication_item_ids_for_author' do
    let(:fake_body) { '<xml></xml>' }
    it 'requests the publication catalog resource' do
      stub_request(:any, /#{Settings.SCIENCEWIRE.BASE_URI}.*/)
      client.matched_publication_item_ids_for_author(fake_body)
      expect(a_post(
        '/PublicationCatalog/MatchedPublicationItemIdsForAuthor?format=xml'
      ).with(body: fake_body)).to have_been_made
    end
  end
  describe '#matched_publication_item_ids_for_author_and_parse' do
    let(:fake_body) { '<xml></xml>' }
    it 'requests the publication catalog resource' do
      expect(subject).to receive(:parse).once
      expect(subject).to receive(:matched_publication_item_ids_for_author).with(fake_body)
      subject.matched_publication_item_ids_for_author_and_parse(fake_body)
    end
  end
  describe '#parse' do
    context 'with a parseable response' do
      it 'parses and returns an array of ids' do
        parsed_response = subject.parse(publication_item_responses)
        expect(parsed_response).to be_an Array
        expect(parsed_response.count).to eq 4
        expect(parsed_response).to include(29_352_378, 29_187_981, 46_795_732, 47_593_787)
      end
    end
    context 'with an unparseable response' do
      it 'parses and returns an empty array' do
        parsed_response = subject.parse('')
        expect(parsed_response).to be_an Array
        expect(parsed_response.count).to eq 0
      end
    end
  end
end
