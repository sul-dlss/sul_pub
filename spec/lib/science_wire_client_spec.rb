require 'spec_helper'

describe ScienceWireClient do
	let(:science_wire_client) {ScienceWireClient.new}
	describe "#query_sciencewire_by_author_name" do
		context " with common last name, first name, and max rows 4" do

			it "returns a list of 4 sciencewire ids" do
				VCR.use_cassette("sciencewire_client_spec_returns_list_of_4") do
					expect(science_wire_client.query_sciencewire_by_author_name("james", "", "smith", 4)).to have(4).items
				end
			end

		end
		context " with uncommon last name, first name, and max rows 4" do

			it "returns an empty array" do
				VCR.use_cassette("sciencewire_client_spec_returns_empty_array") do
					expect(science_wire_client.query_sciencewire_by_author_name("yukon", "", "ottawa", 4)).to have(0).items
				end
			end

		end
	end

	describe "#get_sciencewire_id_suggestions" do

		it "returns suggestions for email address and name" do
			VCR.use_cassette("sciencewire_client_spec_returns_suggestions_for_email") do
				expect(
					science_wire_client.
						get_sciencewire_id_suggestions("edler", "alice", "", "alice.edler@stanford.edu", [])).
					to have_at_least(4).items
			end
		end

		it "gets suggestions from journals and conference proceedings" do
		  VCR.use_cassette("sciencewire_client_spec_searches_journals_and_proceedings") do
				expect(
					science_wire_client.
						get_sciencewire_id_suggestions("benson", "sally", "", "smbenson@stanford.edu", [])).
					to have_at_least(8).items
			end
		end

	end

	describe "#get_full_sciencewire_pubs_for_wos_ids" do

	  it "returns a Nokogiri::XML::Document containing all SW pubs when passed an array of WebOfScience ids" do
	    VCR.use_cassette("sciencewire_client_spec_gets_sw_pubs_with_wos_ids") do
	      doc = science_wire_client.get_full_sciencewire_pubs_for_wos_ids(['000318550800072', '000317872800004', '000317717300006'])
				expect(doc).to be_a(Nokogiri::XML::Document)
				expect(doc.xpath('//PublicationItem')).to have(3).items
			end
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