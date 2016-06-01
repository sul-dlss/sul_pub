require 'spec_helper'
SingleCov.covered!

describe ScienceWireHarvester, :vcr do
  let(:author_without_seed_data) { create :author, emails_for_harvest: '' }
  let(:author_with_seed_email) { create :author }
  let(:author) { create :author }
  let(:science_wire_harvester) { described_class.new }
  let(:science_wire_client) { science_wire_harvester.sciencewire_client }
  let(:harvest_broker) { instance_double(ScienceWire::HarvestBroker) }
  let(:pub_with_sw_id) { create :pub_with_sw_id }
  let(:pub_with_sw_id_and_pmid) { create :pub_with_sw_id_and_pmid }
  let(:contrib_for_sw_pub) { create :contrib, publication: pub_with_sw_id_and_pmid, author: author }

  describe '#use_author_identities' do
    it 'is a Boolean' do
      expect(subject).to respond_to(:use_author_identities)
      expect(subject.use_author_identities).to be false
    end
    it 'is set by Settings' do
      expect(subject.use_author_identities).to eq(Settings.HARVESTER.USE_AUTHOR_IDENTITIES)
    end
  end

  describe '#use_middle_name' do
    it 'is a Boolean' do
      expect(subject).to respond_to(:use_middle_name)
      expect(subject.use_middle_name).to be true
    end
    it 'is set by Settings' do
      expect(subject.use_middle_name).to eq(Settings.HARVESTER.USE_MIDDLE_NAME)
    end
  end

  describe '#default_institution' do
    it 'is a ScienceWire::AuthorInstitution' do
      expect(subject.default_institution).to be_an ScienceWire::AuthorInstitution
    end
    context 'name' do
      it 'is a String' do
        expect(subject.default_institution).to respond_to(:name)
        expect(subject.default_institution.name).to be_an String
      end
      it 'is set by Settings' do
        expect(subject.default_institution.name).to eq(Settings.HARVESTER.INSTITUTION.name)
      end
    end
    context 'has an institution address' do
      it 'is a ScienceWire::AuthorAddress' do
        expect(subject.default_institution).to respond_to(:address)
        expect(subject.default_institution.address).to be_an ScienceWire::AuthorAddress
      end
      it 'is set by Settings' do
        address_hash = Settings.HARVESTER.INSTITUTION.address.to_hash
        expect(subject.default_institution.address.line1).to eq(address_hash[:line1])
        expect(subject.default_institution.address.line2).to eq(address_hash[:line2])
        expect(subject.default_institution.address.city).to eq(address_hash[:city])
        expect(subject.default_institution.address.state).to eq(address_hash[:state])
        expect(subject.default_institution.address.country).to eq(address_hash[:country])
      end
    end
  end

  describe '#harvest_for_author' do
    before do
      expect(ScienceWire::HarvestBroker).to receive(:new)
        .with(author_without_seed_data, science_wire_harvester,
              alternate_name_query: science_wire_harvester.use_author_identities)
        .and_return(harvest_broker)
    end
    context 'when sciencewire suggestions are made' do
      it 'calls create_contrib_for_pub_if_exists' do
        expect(harvest_broker).to receive(:generate_ids).and_return([42_711_845, 22_686_456])
        expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.with(42_711_845, author_without_seed_data)
        expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.with(22_686_456, author_without_seed_data)
        science_wire_harvester.harvest_for_author(author_without_seed_data)
      end

      context 'and when pub already exists locally' do
        before do
          expect(harvest_broker).to receive(:generate_ids).and_return([42_711_845])
          expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.with(42_711_845, author_without_seed_data).and_return(true)
        end

        it 'adds nothing to pub med retrieval queue' do
          expect do
            science_wire_harvester.harvest_for_author(author_without_seed_data)
          end.to_not change { science_wire_harvester.records_queued_for_pubmed_retrieval }
        end

        it 'adds nothing to sciencewire retrieval queue' do
          expect do
            science_wire_harvester.harvest_for_author(author_without_seed_data)
          end.to_not change { science_wire_harvester.records_queued_for_sciencewire_retrieval }
        end
      end

      context "and when pub doesn't exist locally" do
        it 'adds to sciencewire retrieval queue' do
          expect(harvest_broker).to receive(:generate_ids).and_return([42_711_845])
          expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.with(42_711_845, author_without_seed_data).and_return(false)
          expect do
            science_wire_harvester.harvest_for_author(author_without_seed_data)
          end.to change { science_wire_harvester.records_queued_for_sciencewire_retrieval }
        end
      end
    end

    context 'batch execution for sciencewire queue' do
      def setup(threshold)
        pub_ids = [*42_711_845..(42_711_845 + threshold - 1)]
        expect(harvest_broker).to receive(:generate_ids).and_return(pub_ids).once # generate batch of valid sw_id values
        expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).exactly(threshold).with(instance_of(Fixnum), author_without_seed_data).and_return(false)
      end

      it 'triggers when exceeds threshold' do
        threshold = 100 + 1
        setup(threshold)
        expect(science_wire_harvester).to receive(:process_queued_sciencewire_suggestions).once
        science_wire_harvester.harvest_for_author(author_without_seed_data)
        expect(science_wire_harvester.records_queued_for_sciencewire_retrieval.length).to eq(threshold)
      end

      it 'not triggered when inside the threshold' do
        threshold = 100
        setup(threshold)
        expect(science_wire_harvester).to receive(:process_queued_sciencewire_suggestions).exactly(0)
        science_wire_harvester.harvest_for_author(author_without_seed_data)
        expect(science_wire_harvester.records_queued_for_sciencewire_retrieval.length).to eq(threshold)
      end
    end
  end

  describe '#harvest_pubs_for_all_authors' do
    context 'logging' do
      it 'uses standardized logfile' do
        expect(NotificationManager).to receive(:sciencewire_logger).and_call_original
        expect(subject).not_to receive(:harvest_pubs_for_authors) # authors will be empty
        expect(author.cap_import_enabled).to be_falsey
        subject.harvest_pubs_for_all_authors(author.id, author.id)
      end
    end

    context 'author is not enabled for harvest' do
      it 'does not initiate harvesting' do
        author.cap_import_enabled = false
        author.save
        expect(subject).not_to receive(:harvest_pubs_for_authors)
        subject.harvest_pubs_for_all_authors(author.id, author.id)
      end
    end
  end

  describe '#harvest_pubs_for_author_ids' do
    context 'logging' do
      it 'logs to a standardized location' do
        expect(NotificationManager).to receive(:sciencewire_logger).and_call_original
        expect(subject).to receive(:harvest_pubs_for_authors)
        subject.harvest_pubs_for_author_ids([author.id])
      end
    end

    context 'for valid author' do
      it 'calls harvest_for_author' do
        expect(science_wire_harvester).to receive(:harvest_for_author).exactly(3).times.with(kind_of(Author))
        science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
      end

      it 'calls write_counts_to_log' do
        expect(science_wire_harvester).to receive(:write_counts_to_log).once
        science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
      end
    end

    context 'for invalid author' do
      it 'calls the Notification Manager' do
        expect(NotificationManager).to receive(:error)
        science_wire_harvester.harvest_pubs_for_author_ids([67_676_767_676])
      end
    end

    context 'when no existing publication' do
      it 'adds new publications' do
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).exactly(3).times.and_return([42_711_845, 22_686_456])
        expect do
          science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
        end.to change(Publication, :count).by(2)
      end

      it 'adds new contributions' do
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).exactly(3).times.and_return([42_711_845, 22_686_456])
        expect do
          science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
        end.to change(Contribution, :count).by(6)
      end
    end

    context 'when existing pubmed pub' do
      it 'updates an existing pubmed publication with sciencewire data' do
        pub = pub_with_sw_id_and_pmid
        sw_id = pub.sciencewire_id
        sw_ids = [sw_id]
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).once.and_return(sw_ids)
        expect(science_wire_harvester).to receive(:process_queued_sciencewire_suggestions).once.and_call_original
        expect(science_wire_client).to receive(:get_full_sciencewire_pubs_for_sciencewire_ids).with(sw_ids.join(',')).and_call_original
        expect(science_wire_harvester).to receive(:create_or_update_pub_and_contribution_with_harvested_sw_doc).and_call_original
        # Prior to harvest, modify the sciencewire_id in the db record
        pub.update_attribute(:sciencewire_id, 999)
        expect do
          science_wire_harvester.harvest_pubs_for_author_ids([author_without_seed_data.id])
        end.to_not change(Publication, :count)
        # After the harvest, it should have updated the correct sciencewire_id
        pub.reload
        expect(pub.sciencewire_id).to eq(sw_id)
      end

      it 'does not create duplicate publication' do
        auth = author_without_seed_data
        # Create publication.
        expect(Publication.count).to eq(0)
        pub = pub_with_sw_id_and_pmid
        sw_id = pub.sciencewire_id
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).once.and_return([sw_id])
        # Harvest the same publication and it should not duplicate the publication
        expect do
          science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
        end.to_not change(Publication, :count)
        expect(Publication.count).to eq(1)
        expect(Publication.first.id).to eq(pub.id)
      end

      it 'creates new authorship contributions' do
        auth = author_without_seed_data
        # Create publication.
        pub = pub_with_sw_id_and_pmid
        # Harvest the same publication and it should create an authorship contribution
        sw_id = pub.sciencewire_id
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).once.and_return([sw_id])
        expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.and_call_original
        expect(science_wire_harvester).to receive(:add_contribution_for_harvest_suggestion).once.and_call_original
        expect(Contribution).to receive(:create).once.and_call_original
        expect(auth.publications.count).to eq(0)
        science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
        auth.reload
        expect(auth.publications.count).to eq(1)
      end

      it 'does not create duplicate contributions' do
        auth = author_without_seed_data
        # Create publication.
        pub = pub_with_sw_id_and_pmid
        # Harvest the same publication and it should create an authorship contribution
        sw_id = pub.sciencewire_id
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).twice.and_return([sw_id])
        # HarvestBroker.generate_ids should de-dup the PublicationIds and return an empty array the second time.
        expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.and_call_original
        expect(science_wire_harvester).to receive(:add_contribution_for_harvest_suggestion).once.and_call_original
        expect(Contribution).to receive(:create).once.and_call_original
        expect(auth.publications.count).to eq(0)
        science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
        auth.reload
        expect(auth.publications.count).to eq(1)
        # Try to harvest the same publication and it should not duplicate authorship contribution, because
        # while attempting to harvest the same publication, the HarvestBroker.generate_ids
        # should de-dup the PublicationIds and return an empty array the second time.
        expect(Contribution).not_to receive(:create)
        science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
        auth.reload
        expect(auth.publications.count).to eq(1)
      end
    end

    context 'when existing sciencewire pub' do
      it 'adds to contributions for existing publication' do
        auth = author_without_seed_data
        # Create publication.
        pub = pub_with_sw_id
        sw_id = pub.sciencewire_id
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

      it 'does not create duplicate contributions' do
        auth = author_without_seed_data
        # Create publication.
        pub = pub_with_sw_id
        sw_id = pub.sciencewire_id
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).twice.and_return([sw_id])
        # HarvestBroker.generate_ids should de-dup the PublicationIds and return an empty array the second time.
        expect(science_wire_harvester).to receive(:create_contrib_for_pub_if_exists).once.and_call_original
        expect(science_wire_harvester).to receive(:add_contribution_for_harvest_suggestion).once.and_call_original
        expect(Contribution).to receive(:create).once.and_call_original
        expect(auth.publications.count).to eq(0)
        science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
        auth.reload
        expect(auth.publications.count).to eq(1)
        # Try to harvest the same publication and it should not duplicate authorship contribution, because
        # while attempting to harvest the same publication, the HarvestBroker.generate_ids
        # should de-dup the PublicationIds and return an empty array the second time.
        expect(Contribution).not_to receive(:create)
        science_wire_harvester.harvest_pubs_for_author_ids([auth.id])
        auth.reload
        expect(auth.publications.count).to eq(1)
      end
    end

    context 'when manual pub exists' do
      it 'does not create duplicate pub'
      it 'adds to existing contributions for existing record'
      it 'updates record with sciencewire data'
    end

    context 'when run consecutively' do
      it 'should be idempotent for pubs' do
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).exactly(6).times.and_return([42_711_845, 22_686_456])
        # science_wire_client.should_receive(:get_sciencewire_id_suggestions).exactly(4).times.and_return(['42711845', '22686456'])
        expect do
          science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
        end.to change(Publication, :count).by(2)
        p = Publication.where(sciencewire_id: 42_711_845).first
        utime = p.updated_at.localtime
        sleep(2)
        expect do
          science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
        end.to_not change(Publication, :count)
        expect(p.reload.updated_at.localtime).to eq(utime)
      end
      it 'should be idempotent for contributions' do
        expect(science_wire_client).to receive(:query_sciencewire_by_author_name).exactly(6).times.and_return([42_711_845, 22_686_456])
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

  describe '#harvest_sw_pubs_by_wos_id_for_author' do
    it 'creates ScienceWire Publications with an array of WebOfScience IDs for a given author' do
      auth = create(:author, sunetid: 'pande')
      expect(PubmedSourceRecord.count).to eq(0)
      science_wire_harvester.harvest_sw_pubs_by_wos_id_for_author('pande', %w(000318550800072 000317872800004 000317717300006))
      expect(auth.publications.size).to eq(3)
      pub_hash = auth.publications.first.pub_hash
      expect(pub_hash[:authorship].first[:sul_author_id]).to eq(auth.id)
      expect(pub_hash[:identifier].size).to eq(5)
      expect(PubmedSourceRecord.count).to eq(3)
    end

    it 'does not create empty values in the pub_hash for :pmid or an empty PMID identifier' do
      auth = create(:author, sunetid: 'gorin')
      expect(PubmedSourceRecord.count).to eq(0)
      science_wire_harvester.harvest_sw_pubs_by_wos_id_for_author('gorin', ['000224492700003'])
      expect(auth.publications.size).to eq(1)
      pub_hash = auth.publications.first.pub_hash
      expect(pub_hash[:authorship].first[:sul_author_id]).to eq(auth.id)
      expect(pub_hash[:identifier].select { |id| id[:type] == 'PMID' }).to be_empty
      expect(PubmedSourceRecord.count).to eq(0)
    end

    it 'does not create duplicate publication or contribution' do
      auth = create(:author, sunetid: 'gorin')
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

  describe '#harvest_from_directory_of_wos_id_files' do
    it 'processes only bibtex items of type @inproceedings' do
      auth = create(:author, sunetid: 'mix')
      science_wire_harvester.harvest_from_directory_of_wos_id_files(Rails.root.join('fixtures', 'wos_bibtex', 'mix_dir').to_s)
      expect(auth.publications.size).to eq(1)
    end

    it 'skips empty bibtex files' do
      science_wire_harvester.harvest_from_directory_of_wos_id_files(Rails.root.join('fixtures', 'wos_bibtex', 'empty_dir').to_s)
      expect(science_wire_harvester.file_count).to eq(0)
    end
  end

  describe '#logger' do
    it 'uses standardized logfile' do
      expect(NotificationManager).to receive(:sciencewire_logger)
      subject.send(:logger) # private method
    end
  end
end
