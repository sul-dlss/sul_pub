require 'spec_helper'
##
# Requires private factories in `spec/factories/author.local.rb`
feature 'Harvest Brokering', 'data-integration': true do
  let(:harvester) { ScienceWireHarvester.new }
  let(:broker) do
    ScienceWire::HarvestBroker.new(
      author, harvester, alternate_name_query: true
    )
  end
  let(:ids) { broker.ids_for_author }
  let(:alt_ids) { broker.ids_for_alternate_names }
  ##
  # These integration specs test the HarvestBroker using Author's with various
  # alternate identities. Values are testing current functionality to create a
  # baseline for future improvements.
  feature 'for alternate names' do
    context 'an author with many seed publications' do
      let(:author) { create(:author_russ_altman) }
      scenario 'Russ Altman' do
        expect(ids.count).to be > 100
        expect(alt_ids.count).to be > 100
        expect(broker.generate_ids.count).to be >= ids.count
      end
    end
    context 'an author with no seed publications' do
      let(:author) { create(:author_michael_halaas) }
      scenario 'Michael Halaas' do
        expect(ids.count).to be_between(0, 10).exclusive
        expect(alt_ids.count).to be_between(0, 10).exclusive
      end
    end
    context 'an author with many alternate identities' do
      let(:author) { create(:author_roy_pea) }
      scenario 'Roy Pea' do
        expect(ids.count).to be_between(20, 30).exclusive
        expect(alt_ids.count).to be_between(35, 45).exclusive #40 as of 2016.05.26
      end
    end
  end
end
