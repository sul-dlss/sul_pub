require 'spec_helper'

describe ScienceWireHarvester do
  let(:author_without_seed_data) { create :author, emails_for_harvest: '' }
  let(:author_with_seed_email) { create :author }
  let(:author) { create :author }
  let(:science_wire_harvester) { ScienceWireHarvester.new }
  let(:science_wire_client) { science_wire_harvester.sciencewire_client }
  let(:pub_with_sw_id) { create :pub_with_sw_id }
  let(:pub_with_sw_id_and_pmid) { create :pub_with_sw_id_and_pmid }
  let(:contrib_for_sw_pub) { create :contrib, publication: pub_with_sw_id_and_pmid, author: author }

  describe '#harvest_for_author' do
    context 'for author with first name last name only' do
      it 'uses the client query by name method', :vcr do
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).and_call_original
        science_wire_harvester.harvest_for_author(author_without_seed_data)
      end

      it "doesn't use the client query by email or seed method", :vcr do
        expect(science_wire_client).not_to receive(:get_sciencewire_id_suggestions)
        science_wire_harvester.harvest_for_author(author_without_seed_data)
      end
    end

    context 'seed records and querying' do
      it 'uses the publication query by name if the author has less than 10 seeds' do
        skip
        # science_wire_client.should_not_receive(:query_sciencewire_by_author_name)
        # science_wire_harvester.harvest_for_author(author_with_seed_email)
      end

      it 'uses the suggestion query if the author has more than 10 seeds' do
        skip
        # science_wire_client.should_receive(:get_sciencewire_id_suggestions).and_call_original
        # science_wire_harvester.harvest_for_author(author_with_seed_email)
      end
    end

    context 'when sciencewire suggestions are made' do
      it 'calls create_contrib_for_pub_if_exists' do
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).and_return(%w(42711845 22686456))
        expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.with('42711845', author_without_seed_data)
        expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.with('22686456', author_without_seed_data)
        science_wire_harvester.harvest_for_author(author_without_seed_data)
      end
      context 'and when pub already exists locally' do
        it 'adds nothing to pub med retrieval queue' do
          expect(science_wire_client).to receive(:query_sciencewire_by_author_name).and_return(['42711845'])
          expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.with('42711845', author_without_seed_data).and_return(true)
          expect do
            science_wire_harvester.harvest_for_author(author_without_seed_data)
          end.to_not change { science_wire_harvester.records_queued_for_pubmed_retrieval }
        end
        it 'adds nothing to sciencewire retrieval queue' do
          expect(science_wire_client).to receive(:query_sciencewire_by_author_name).and_return(['42711845'])
          expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.with('42711845', author_without_seed_data).and_return(true)
          expect do
            science_wire_harvester.harvest_for_author(author_without_seed_data)
          end.to_not change { science_wire_harvester.records_queued_for_pubmed_retrieval }
        end
      end
      context "and when pub doesn't exist locally" do
        it 'adds to sciencewire retrieval queue' do
          expect(science_wire_client).to receive(:query_sciencewire_by_author_name).and_return(['42711845'])
          expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.with('42711845', author_without_seed_data).and_return(false)
          expect do
            science_wire_harvester.harvest_for_author(author_without_seed_data)
          end.to_not change { science_wire_harvester.records_queued_for_pubmed_retrieval }
        end
      end
    end

    it 'triggers batch call when queue is full' do
      skip
    end
  end

  describe '#harvest_pubs_for_author_ids' do
    context 'for valid author' do
      it 'calls harvest_for_author' do
        expect(science_wire_harvester).to receive(:harvest_for_author).exactly(3).times.with(kind_of(Author))
        science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
      end
      it 'calls write_counts_to_log' do
        VCR.use_cassette('sciencewire_harvester_writes_counts_to_log') do
          expect(science_wire_harvester).to receive(:write_counts_to_log).once
          science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
        end
      end
    end
    context 'for invalid author' do
      it 'calls the Notification Manager' do
        VCR.use_cassette('sciencewire_harvester_calls_notification_manager') do
          expect(NotificationManager).to receive(:handle_harvest_problem)
          science_wire_harvester.harvest_pubs_for_author_ids([67_676_767_676])
        end
      end
    end
    context 'when no existing publication' do
      it 'adds new publications' do
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).exactly(3).times.and_return(%w(42711845 22686456))
        expect do
          science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
        end.to change(Publication, :count).by(2)
      end
      it 'adds new contributions' do
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).exactly(3).times.and_return(%w(42711845 22686456))
        expect do
          science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
        end.to change(Contribution, :count).by(6)
      end
    end
    context 'when existing pubmed pub' do
      it 'updates an existing pubmed publication with sciencewire data' do
        VCR.use_cassette('sciencewire_harvester_update_pubmed_with_sw_data') do
          pub = pub_with_sw_id_and_pmid
          sw_id = pub.sciencewire_id.to_s
          expect(science_wire_client).to receive(:query_sciencewire_by_author_name).once.and_return([sw_id])
          expect(science_wire_harvester).to receive(:process_queued_sciencewire_suggestions).once.and_call_original
          expect(science_wire_client).to receive(:get_full_sciencewire_pubs_for_sciencewire_ids).with(sw_id).and_call_original
          expect(science_wire_harvester).to receive(:create_or_update_pub_and_contribution_with_harvested_sw_doc).and_call_original
          expect_any_instance_of(Publication).to receive(:build_from_sciencewire_hash).once.and_call_original
          # Prior to harvest, modify the sciencewire_id in the db record
          pub.update_attribute(:sciencewire_id, 999)
          expect do
            science_wire_harvester.harvest_pubs_for_author_ids([author_without_seed_data.id])
          end.to_not change(Publication, :count)
          # After the harvest, it should have updated the correct sciencewire_id
          pub.reload
          expect(pub.sciencewire_id.to_s).to eq(sw_id)
        end
      end
      it 'does not create duplicate publication' do
        auth = author_without_seed_data
        VCR.use_cassette('sciencewire_harvester_no_dups_for_pmid_publication') do
          # Create publication.
          expect(Publication.count).to eq(0)
          pub = pub_with_sw_id_and_pmid
          sw_id = pub.sciencewire_id.to_s
          expect(science_wire_client).to receive(:query_sciencewire_by_author_name).once.and_return([sw_id])
          # Harvest the same publication and it should not duplicate the publication
          expect do
            science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
          end.to_not change(Publication, :count)
          expect(Publication.count).to eq(1)
          expect(Publication.first.id).to eq(pub.id)
        end
      end
      it 'creates new authorship contributions' do
        auth = author_without_seed_data
        VCR.use_cassette('sciencewire_harvester_creates_pmid_contributions') do
          # Create publication.
          pub = pub_with_sw_id_and_pmid
          # Harvest the same publication and it should create an authorship contribution
          sw_id = pub.sciencewire_id.to_s
          expect(science_wire_client).to receive(:query_sciencewire_by_author_name).once.and_return([sw_id])
          expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.and_call_original
          expect(science_wire_harvester).to receive(:add_contribution_for_harvest_suggestion).once.and_call_original
          expect(Contribution).to receive(:create).once.and_call_original
          expect(auth.publications.count).to eq(0)
          science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
          auth.reload
          expect(auth.publications.count).to eq(1)
        end
      end
      it 'does not create duplicate contributions' do
        auth = author_without_seed_data
        VCR.use_cassette('sciencewire_harvester_no_dups_for_pmid_contributions') do
          # Create publication.
          pub = pub_with_sw_id_and_pmid
          # Harvest the same publication and it should create an authorship contribution
          sw_id = pub.sciencewire_id.to_s
          expect(science_wire_client).to receive(:query_sciencewire_by_author_name).twice.and_return([sw_id])
          expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).twice.and_call_original
          expect(science_wire_harvester).to receive(:add_contribution_for_harvest_suggestion).twice.and_call_original
          expect(Contribution).to receive(:create).once.and_call_original
          expect(auth.publications.count).to eq(0)
          science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
          auth.reload
          expect(auth.publications.count).to eq(1)
          # Harvest the same publication and it should not duplicate authorship contribution
          expect(Contribution).not_to receive(:create)
          science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
          auth.reload
          expect(auth.publications.count).to eq(1)
        end
      end
    end
    context 'when existing sciencewire pub' do
      it 'adds to contributions for existing publication' do
        auth = author_without_seed_data
        VCR.use_cassette('sciencewire_harvester_adds_contribution') do
          # Create publication.
          pub = pub_with_sw_id
          sw_id = pub.sciencewire_id.to_s
          expect(science_wire_client).to receive(:query_sciencewire_by_author_name).once.and_return([sw_id])
          # Harvest an existing publication and it should create a new authorship contribution
          expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).and_call_original
          expect(science_wire_harvester).to receive(:add_contribution_for_harvest_suggestion).and_call_original
          expect(Contribution).to receive(:create).once.and_call_original
          expect(auth.publications.count).to eq(0)
          science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
          auth.reload
          expect(auth.publications.count).to eq(1)
        end
      end
      it 'does not create duplicate contributions' do
        auth = author_without_seed_data
        VCR.use_cassette('sciencewire_harvester_no_dups_for_contributions') do
          # Create publication.
          pub = pub_with_sw_id
          sw_id = pub.sciencewire_id.to_s
          expect(science_wire_client).to receive(:query_sciencewire_by_author_name).twice.and_return([sw_id])
          expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).twice.and_call_original
          expect(science_wire_harvester).to receive(:add_contribution_for_harvest_suggestion).twice.and_call_original
          expect(Contribution).to receive(:create).once.and_call_original
          expect(auth.publications.count).to eq(0)
          science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
          auth.reload
          expect(auth.publications.count).to eq(1)
          # Harvest the same publication and it should not duplicate authorship contribution
          expect(Contribution).not_to receive(:create)
          science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
          auth.reload
          expect(auth.publications.count).to eq(1)
        end
      end
    end
    context 'when manual pub exists' do
      it "doesn't create duplicate pub"
      it 'adds to existing contributions for existing record'
      it 'updates record with sciencewire data'
    end
    context 'when run consecutively' do
      it 'should be idempotent for pubs' do
        VCR.use_cassette('sciencewire_harvester_idempotent_for_pubs') do
          expect(science_wire_client).to receive(:query_sciencewire_by_author_name).exactly(6).times.and_return(%w(42711845 22686456))
          # science_wire_client.should_receive(:get_sciencewire_id_suggestions).exactly(4).times.and_return(['42711845', '22686456'])
          expect do
            science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
          end.to change(Publication, :count).by(2)
          p = Publication.where(sciencewire_id: '42711845').first
          utime = p.updated_at.localtime
          sleep(2)
          expect do
            science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
          end.to_not change(Publication, :count)
          expect(p.reload.updated_at.localtime).to eq(utime)
        end
      end
      it 'should be idempotent for contributions' do
        VCR.use_cassette('sciencewire_harvester_idempotent_for_contribs') do
          expect(science_wire_client).to receive(:query_sciencewire_by_author_name).exactly(6).times.and_return(%w(42711845 22686456))
          # science_wire_client.should_receive(:get_sciencewire_id_suggestions).exactly(4).times.and_return(['42711845', '22686456'])
          expect do
            science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
          end.to change(Contribution, :count).by(6)
          expect do
            science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
          end.to_not change(Contribution, :count)
        end
      end
    end
  end

  describe '#harvest_for_all_authors' do
  end

  describe '#harvest_sw_pubs_by_wos_id_for_author' do
    it 'creates ScienceWire Publications with an array of WebOfScience IDs for a given author' do
      auth = create(:author, sunetid: 'pande')
      VCR.use_cassette('sciencewire_harvester_wos_to_sw_for_author') do
        expect(PubmedSourceRecord.count).to eq(0)
        science_wire_harvester.harvest_sw_pubs_by_wos_id_for_author('pande', %w(000318550800072 000317872800004 000317717300006))
        expect(auth.publications.size).to eq(3)
        pub_hash = auth.publications.first.pub_hash
        expect(pub_hash[:authorship].first[:sul_author_id]).to eq(auth.id)
        expect(pub_hash[:identifier].size).to eq(5)
        expect(PubmedSourceRecord.count).to eq(3)
      end
    end

    it 'does not create empty values in the pub_hash for :pmid or an empty PMID identifier' do
      auth = create(:author, sunetid: 'gorin')
      VCR.use_cassette('sciencewire_harvester_wos_no_pubmed') do
        expect(PubmedSourceRecord.count).to eq(0)
        science_wire_harvester.harvest_sw_pubs_by_wos_id_for_author('gorin', ['000224492700003'])
        expect(auth.publications.size).to eq(1)
        pub_hash = auth.publications.first.pub_hash
        expect(pub_hash[:authorship].first[:sul_author_id]).to eq(auth.id)
        expect(pub_hash[:identifier].select { |id| id[:type] == 'PMID' }).to be_empty
        expect(PubmedSourceRecord.count).to eq(0)
      end
    end

    it 'does not create duplicate publication or contribution' do
      auth = create(:author, sunetid: 'gorin')
      VCR.use_cassette('sciencewire_harvester_wos_no_dups') do
        # Harvest a new publication by sciencewire_id
        expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).twice.and_call_original
        expect(science_wire_harvester).to receive(:add_contribution_for_harvest_suggestion).twice.and_call_original
        expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists_by_author_ids).and_call_original
        expect(auth.publications.count).to eq(0)
        science_wire_harvester.harvest_sw_pubs_by_wos_id_for_author('gorin', ['000224492700003'])
        auth.reload
        expect(auth.publications.count).to eq(1)
        expect(SciencewireSourceRecord.count).to eq(1)
        expect(PubmedSourceRecord.count).to eq(0)
        # Harvest the same publication and it should not duplicate.
        expect(science_wire_harvester).not_to receive(:create_contrib_for_pub_if_exists_by_author_ids)
        expect(science_wire_harvester).not_to receive(:create_or_update_pub_and_contribution_with_harvested_sw_doc)
        science_wire_harvester.harvest_sw_pubs_by_wos_id_for_author('gorin', ['000224492700003'])
        auth.reload
        expect(auth.publications.count).to eq(1)
        expect(SciencewireSourceRecord.count).to eq(1)
        expect(PubmedSourceRecord.count).to eq(0)
      end
    end
  end

  describe '#harvest_from_directory_of_wos_id_files' do
    it 'processes only bibtex items of type @inproceedings' do
      auth = create(:author, sunetid: 'mix')
      VCR.use_cassette('sciencewire_harvester_wos_mix') do
        science_wire_harvester.harvest_from_directory_of_wos_id_files(Rails.root.join('fixtures', 'wos_bibtex', 'mix_dir').to_s)
        expect(auth.publications.size).to eq(1)
      end
    end

    it 'skips empty bibtex files' do
      science_wire_harvester.harvest_from_directory_of_wos_id_files(Rails.root.join('fixtures', 'wos_bibtex', 'empty_dir').to_s)
      expect(science_wire_harvester.file_count).to eq(0)
    end
  end
end
