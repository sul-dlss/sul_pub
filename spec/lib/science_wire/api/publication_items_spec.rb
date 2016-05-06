require 'spec_helper'

describe ScienceWire::API::PublicationItems do
  let(:client) do
    ScienceWire::Client.new(
      license_id: 'license', host: Settings.SCIENCEWIRE.HOST
    )
  end
  describe '#publication_items' do
    let(:fake_body) { '<xml></xml>' }
    let(:ids) { 'abc,123' }
    it 'requests the publication query' do
      stub_request(:any, /#{Settings.SCIENCEWIRE.BASE_URI}.*/)
      client.publication_items(ids)
      expect(a_get(
        '/PublicationCatalog/PublicationItems?format=xml'
      ).with(query: {
        format: 'xml',
        publicationItemIDs: ids
      })).to have_been_made
    end
  end
end
