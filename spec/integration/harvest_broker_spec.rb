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
  let(:seeds) { author.approved_sciencewire_ids }
  ##
  # These integration specs test the HarvestBroker using Author's with various
  # alternate identities. Values are testing current functionality to create a
  # baseline for future improvements.
  feature 'for alternate names' do
    context 'an author with many seed publications' do
      let(:author) { create(:author_russ_altman) }
      scenario 'Russ Altman' do
        # broker calls smart search for an author with > 50 seeds
        expect(seeds.count).to be > 50
        # Calls smart query twice (called by ids_for_author and generate_ids)
        expect(broker).to receive(:ids_from_smart_query).twice.and_call_original
        smart_ids = ids
        expect(smart_ids.count).to be > 100
        # broker calls dumb search for author alt-names; for this author, there
        # is only one valid alternative identity for dumb search.  So, it will
        # be called twice (called by ids_for_alternate_names and generate_ids).
        expect(broker).to receive(:ids_from_dumb_query).twice.and_call_original
        alt_pubs = alt_ids - smart_ids
        expect(alt_pubs).not_to be_empty # alt-names add something
        new_pubs = broker.generate_ids # this removes existing pubs
        expect(new_pubs - seeds).not_to be_empty # seeds should be removed already
        expect(new_pubs - smart_ids).not_to be_empty # alt-names add something
      end
      describe 'seed_list' do
        it 'returns an Array<Integer>' do
          expect(seeds).to be_an Array
          expect(seeds).not_to be_empty
          expect(seeds.first).to be_an Integer
        end
      end
    end
    context 'an author with no seed publications' do
      let(:author) { create(:author_michael_halaas) }
      scenario 'Michael Halaas' do
        # broker calls dumb search for an author with < 50 seeds
        expect(seeds.count).to be < 50
        expect(broker).not_to receive(:ids_from_smart_query)
        expect(broker).to receive(:ids_from_dumb_query).twice.and_call_original
        expect(ids.count).to be_between(0, 10).exclusive
        expect(alt_ids.count).to be_between(0, 10).exclusive
      end
    end
    context 'an author with many alternate identities' do
      let(:author) { create(:author_roy_pea) }
      scenario 'Roy Pea' do
        # broker calls dumb search for an author with < 50 seeds
        expect(seeds.count).to be < 50
        expect(broker).not_to receive(:ids_from_smart_query)
        # author.alternative_identities.select{|author_identity| required_data_for_alt_names_search(author_identity)}.count == 11
        valid_alt_name_count = 11
        expected_calls = 1 + valid_alt_name_count
        expect(broker).to receive(:ids_from_dumb_query).exactly(expected_calls).and_call_original
        expect(ids.count).to be_between(20, 30).exclusive
        expect(alt_ids.count).to be_between(30, 40).exclusive #34 as of 2016.05.30 using 30 year period
      end
    end
  end
end
