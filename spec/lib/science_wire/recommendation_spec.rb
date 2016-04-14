require 'spec_helper'

describe ScienceWire::Recommendation do
  let(:client) do
    ScienceWire::Client.new(
      licence_id: 'license', host: Settings.SCIENCEWIRE.HOST
    )
  end
  describe '#recommendation' do
    let(:fake_body) { '<xml></xml>' }
    before do
      stub_post(Settings.SCIENCEWIRE.RECOMMENDATION_PATH)
        .with(query: {format: 'xml'})
    end
    it 'requests the publication catalog resource' do
      client.recommendation(fake_body)
      expect(a_post(
        '/PublicationCatalog/MatchedPublicationItemIdsForAuthor?format=xml'
      ).with(body: fake_body)).to have_been_made
    end
  end
end
