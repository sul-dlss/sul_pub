require 'spec_helper'


describe Publication do
	let(:publication) { FactoryGirl.create :publication }
	let!(:publication_with_contributions) { create :publication_with_contributions, contributions_count:2  } 
	describe "#sync_publication_hash" do
		context " with multiple contributions " do
	
			it " writes the correct authorship field to the pub_hash " 

			it " creates a new contribution for a new authorship entry in the pub_hash "

		end
	end
end

