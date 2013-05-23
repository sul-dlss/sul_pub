require 'spec_helper'

describe SulBib::API_samples do
	before :each do
      host! 'localhost:3000'
    end

	it 'grabs the get_pub_out data' do
		get "/samples/get_pub_out" 
		puts response

		response.status.should == 200
		response.body.should == ''
	end

end