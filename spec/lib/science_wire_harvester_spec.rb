require 'spec_helper'

describe ScienceWireHarvester do
	let(:author_without_seed_data) { create :author, emails_for_harvest: "" }
	let(:author_with_seed_email) { create :author }
	let(:author) { create :author }
	let(:science_wire_harvester) {ScienceWireHarvester.new}
	let(:science_wire_client) {science_wire_harvester.sciencewire_client}
	let(:pub_with_sw_id_and_pmid) {create :pub_with_sw_id_and_pmid}
	let(:contrib_for_sw_pub) { create :contrib, publication: pub_with_sw_id_and_pmid, author: author}

	describe "#harvest_for_author" do

		context "for author with first name last name only" do

			it "uses the client query by name method" do
				science_wire_client.should_receive(:query_sciencewire_by_author_name).and_call_original
				science_wire_harvester.harvest_for_author(author_without_seed_data)
			end

			it "doesn't use the client query by email or seed method" do
				science_wire_client.should_not_receive(:get_sciencewire_id_suggestions)
				science_wire_harvester.harvest_for_author(author_without_seed_data)
			end
		end

		context "seed records and querying" do

			it "uses the publication query by name if the author has less than 10 seeds" do
			  pending
        # science_wire_client.should_not_receive(:query_sciencewire_by_author_name)
        # science_wire_harvester.harvest_for_author(author_with_seed_email)
			end

			it "uses the suggestion query if the author has more than 10 seeds" do
			  pending
        # science_wire_client.should_receive(:get_sciencewire_id_suggestions).and_call_original
        # science_wire_harvester.harvest_for_author(author_with_seed_email)
			end

		end

		context "when sciencewire suggestions are made" do
			it "calls create_contrib_for_pub_if_exists" do
				science_wire_client.should_receive(:query_sciencewire_by_author_name).and_return(['42711845', '22686456'])
				science_wire_harvester.should_receive(:create_contrib_for_pub_if_exists).once.with('42711845', author_without_seed_data)
				science_wire_harvester.should_receive(:create_contrib_for_pub_if_exists).once.with('22686456', author_without_seed_data)
				science_wire_harvester.harvest_for_author(author_without_seed_data)
			end
			context "and when pub already exists locally" do
				it "adds nothing to pub med retrieval queue" do
					science_wire_client.should_receive(:query_sciencewire_by_author_name).and_return(['42711845'])
					science_wire_harvester.should_receive(:create_contrib_for_pub_if_exists).once.with('42711845', author_without_seed_data).and_return(true)
					expect {
						science_wire_harvester.harvest_for_author(author_without_seed_data)
						}.to_not change{science_wire_harvester.records_queued_for_pubmed_retrieval}
				end
				it "adds nothing to sciencewire retrieval queue" do
					science_wire_client.should_receive(:query_sciencewire_by_author_name).and_return(['42711845'])
					science_wire_harvester.should_receive(:create_contrib_for_pub_if_exists).once.with('42711845', author_without_seed_data).and_return(true)
					expect {
						science_wire_harvester.harvest_for_author(author_without_seed_data)
						}.to_not change{science_wire_harvester.records_queued_for_pubmed_retrieval}
				end
			end
			context "and when pub doesn't exist locally" do
				it "adds to sciencewire retrieval queue" do
					science_wire_client.should_receive(:query_sciencewire_by_author_name).and_return(['42711845'])
					science_wire_harvester.should_receive(:create_contrib_for_pub_if_exists).once.with('42711845', author_without_seed_data).and_return(false)

					expect {
						science_wire_harvester.harvest_for_author(author_without_seed_data)
						}.to_not change{science_wire_harvester.records_queued_for_pubmed_retrieval}
				end
			end
		end

		it "triggers batch call when queue is full" do
			pending
		end
	end

	describe "#get_seed_list_for_author" do
		it "returns an array for an author" do
			seed_list = science_wire_harvester.get_seed_list_for_author(author_with_seed_email)
			expect(seed_list).to respond_to(:each)
		end
	end

	describe "#harvest_pubs_for_author_ids" do
		context "for valid author" do
			it "calls harvest_for_author" do
				science_wire_harvester.should_receive(:harvest_for_author).exactly(3).times.with(kind_of(Author))
				science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
			end
			it "calls write_counts_to_log" do
				VCR.use_cassette("sciencewire_harvester_writes_counts_to_log") do
					science_wire_harvester.should_receive(:write_counts_to_log).once
					science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
				end
			end
		end
		context "for invalid author" do
			it "calls the Notification Manager" do
				VCR.use_cassette("sciencewire_harvester_calls_notification_manager") do
					NotificationManager.should_receive(:handle_harvest_problem)
					science_wire_harvester.harvest_pubs_for_author_ids([67676767676])
				end
			end
		end
		context "when no existing publication" do
			it "adds new publications" do
				VCR.use_cassette("sciencewire_harvester_adds_new_publication") do
					science_wire_client.should_receive(:query_sciencewire_by_author_name).exactly(3).times.and_return(['42711845', '22686456'])
					#science_wire_client.should_not_receive(:get_sciencewire_id_suggestions)
					expect{
						science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
						}.to change(Publication, :count).by(2)
				end
			end
			it "adds new contributions" do
				VCR.use_cassette("sciencewire_harvester_adds_new_contributions") do
					science_wire_client.should_receive(:query_sciencewire_by_author_name).exactly(3).times.and_return(['42711845', '22686456'])
					#science_wire_client.should_receive(:get_sciencewire_id_suggestions).twice.and_return(['42711845', '22686456'])
					expect {
						science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
						}.to change(Contribution, :count).by(6)

				end
			end
		end
		context "when existing pubmed pub" do
			it "updates an existing pubmed publication with sciencewire data" do
				VCR.use_cassette('sciencewire_harvester_update_pubmed_with_sw_data') do
					sw_id = pub_with_sw_id_and_pmid.sciencewire_id.to_s

					science_wire_client.should_receive(:query_sciencewire_by_author_name).once.and_return([sw_id])
					pub_with_sw_id_and_pmid.update_attribute(:sciencewire_id, 2)
					#expect(pub_with_sw_id_and_pmid.sciencewire_id).to change

					expect {
						science_wire_harvester.harvest_pubs_for_author_ids([author_without_seed_data.id])
						}.to_not change(Publication, :count)
					pub_with_sw_id_and_pmid.reload
					expect(pub_with_sw_id_and_pmid.sciencewire_id.to_s).to eq(sw_id)
				end
			end
			it "doesn't create a duplicate publication"
		end
		context "when existing contribution" do

			it "doesn't create a duplicate contribution" do
				pub_with_sw_id_and_pmid
			end
			it "doesn't modify an existing contribution"
		end
		context "when existing sciencewire pub" do
			it "doesn't create duplicate pub"
			it "adds to existing contributions for existing record"
		end
		context "when manual pub exists" do
			it "doesn't create duplicate pub"
			it "adds to existing contributions for existing record"
			it "updates record with sciencewire data"
		end
		context "when run consecutively" do
			it "should be idempotent for pubs" do
				VCR.use_cassette("sciencewire_harvester_idempotent_for_pubs") do
					science_wire_client.should_receive(:query_sciencewire_by_author_name).exactly(6).times.and_return(['42711845', '22686456'])
					#science_wire_client.should_receive(:get_sciencewire_id_suggestions).exactly(4).times.and_return(['42711845', '22686456'])
					expect {
						science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
						}.to change(Publication, :count).by(2)
					expect {
						science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
						}.to_not change(Publication, :count)
				end
			end
			it "should be idempotent for contributions" do
				VCR.use_cassette("sciencewire_harvester_idempotent_for_contribs") do
					science_wire_client.should_receive(:query_sciencewire_by_author_name).exactly(6).times.and_return(['42711845', '22686456'])
					#science_wire_client.should_receive(:get_sciencewire_id_suggestions).exactly(4).times.and_return(['42711845', '22686456'])
					expect {
						science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
						}.to change(Contribution, :count).by(6)
					expect {
						science_wire_harvester.harvest_pubs_for_author_ids([author.id, author_with_seed_email.id, author_without_seed_data.id])
						}.to_not change(Contribution, :count)
				end
			end
		end
	end

	describe "#harvest_for_all_authors" do

	end

	describe "#harvest_sw_pubs_by_wos_id_for_author" do

	  it "creates/updates ScienceWire Publications with an array of WebOfScience IDs for a given author" do
	    auth = create(:author, :sunetid => 'pande')
	    VCR.use_cassette("sciencewire_harvester_wos_to_sw_for_author") do
	      expect(PubmedSourceRecord.count).to eq(0)
	      science_wire_harvester.harvest_sw_pubs_by_wos_id_for_author('pande', ['000318550800072', '000317872800004', '000317717300006'])
        expect(auth.publications).to have(3).items
        pub_hash = auth.publications.first.pub_hash
        expect(pub_hash[:authorship].first[:sul_author_id]).to eq(auth.id)
        expect(pub_hash[:identifier]).to have(4).items
        expect(PubmedSourceRecord.count).to eq(3)
      end
	  end

	  it "does not create empty values in the pub_hash for :pmid or an empty PMID identifier" do
	    auth = create(:author, :sunetid => 'gorin')
	    VCR.use_cassette("sciencewire_harvester_wos_no_pubmed") do
	      expect(PubmedSourceRecord.count).to eq(0)
	      science_wire_harvester.harvest_sw_pubs_by_wos_id_for_author('gorin', ['000224492700003'])
        expect(auth.publications).to have(1).items
        pub_hash = auth.publications.first.pub_hash
        expect(pub_hash[:authorship].first[:sul_author_id]).to eq(auth.id)
        expect(pub_hash[:identifier].select {|id| id[:type] == 'PMID'}).to be_empty
        expect(PubmedSourceRecord.count).to eq(0)
      end
	  end

	end

	describe "#harvest_from_directory_of_wos_id_files" do

	  it "skips bibtex items of type @inproceedings" do
	    auth = create(:author, :sunetid => 'mix')
      VCR.use_cassette("sciencewire_harvester_wos_mix") do
        science_wire_harvester.harvest_from_directory_of_wos_id_files(Rails.root.join('fixtures', 'wos_bibtex', 'mix_dir').to_s)
        expect(auth.publications).to have(2).items
      end
	  end

	  it "skips empty bibtex files" do
	    science_wire_harvester.harvest_from_directory_of_wos_id_files(Rails.root.join('fixtures', 'wos_bibtex', 'empty_dir').to_s)
	    expect(science_wire_harvester.file_count).to eq(0)
	  end

	end

end