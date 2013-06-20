require 'spec_helper'

describe ScienceWireClient do
	let(:science_wire_client) {ScienceWireClient.new}
	describe "#query_sciencewire_by_author_name" do
		context " with common last name, first name, and max rows 4" do
	
			it "returns a list of 4 sciencewire ids" do
				expect(science_wire_client.query_sciencewire_by_author_name("james", "smith", 4)).to have(4).items
			end

		end
		context " with uncommon last name, first name, and max rows 4" do
	
			it "returns an empty array" do
				
				expect(science_wire_client.query_sciencewire_by_author_name("yukon", "ottawa", 4)).to have(0).items
			end

		end
	end
	

end