require 'spec_helper'

describe ScienceWireHarvester do
	let(:author_without_seed_data) { create :author, emails_for_harvest: "" }
	let(:author_with_seed_email) { create :author }
	let(:science_wire_harvester) {ScienceWireHarvester.new}
	let(:science_wire_client) {science_wire_harvester.sciencewire_client}

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

		context "for author with emails" do
	
			it "doesn't uses the client query by name method" do	
				science_wire_client.should_not_receive(:query_sciencewire_by_author_name)
				science_wire_harvester.harvest_for_author(author_with_seed_email)
			end

			it "uses the client query by email or seed method" do	
				science_wire_client.should_receive(:get_sciencewire_id_suggestions).and_call_original
				science_wire_harvester.harvest_for_author(author_with_seed_email)
			end

		end
	end

	describe "#get_seed_list_for_author" do
		it "returns an array for an author" do
			seed_list = science_wire_harvester.get_seed_list_for_author(author_with_seed_email)
			expect(seed_list).to respond_to(:each)
		end
	end
	

end