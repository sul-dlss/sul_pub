require 'spec_helper'

describe ScienceWireClient do
	let(:science_wire_client) {ScienceWireClient.new}
	describe "#query_sciencewire_by_author_name" do
		context " with common last name, first name, and max rows 4" do
	
			it "returns a list of 4 sciencewire ids" do
				expect(science_wire_client.query_sciencewire_by_author_name("james", "", "smith", 4)).to have(4).items
			end

		end
		context " with uncommon last name, first name, and max rows 4" do
	
			it "returns an empty array" do
				
				expect(science_wire_client.query_sciencewire_by_author_name("yukon", "", "ottawa", 4)).to have(0).items
			end

		end
	end

	describe "#get_sciencewire_id_suggestions" do

		it "returns suggestions for email address and name" do
			expect(
				science_wire_client.
					get_sciencewire_id_suggestions("edler", "alice", "", "alice.edler@stanford.edu", [])).
				to have_at_least(3).items
		end

	end
	
	describe "#pull_records_from_sciencewire_for_pmids" do

	end

	describe "#query_sciencewire_for_publication" do

	end

	describe "#query_sciencewire" do

	end

	describe "#get_full_sciencewire_pubs_for_sciencewire_ids" do

	end

	describe "#get_sw_xml_source_for_sw_id" do

	end

end