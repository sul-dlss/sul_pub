require 'spec_helper'

describe ScienceWire::PublicationQuery do
  let(:client) do
    ScienceWire::Client.new(
      licence_id: 'license', host: Settings.SCIENCEWIRE.HOST
    )
  end
  describe '#publication_query' do
    let(:fake_body) { '<xml></xml>' }
    before do
      stub_post(Settings.SCIENCEWIRE.PUBLICATION_QUERY_PATH)
        .with(query: {format: 'xml'})
    end
    it 'requests the publication query' do
      client.publication_query(fake_body)
      expect(a_post(
        '/PublicationCatalog/PublicationQuery?format=xml'
      ).with(body: fake_body)).to have_been_made
    end
  end
end
