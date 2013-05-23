require 'spec_helper'

describe SulBib::API_authorship do
	
	it 'rejects un update without author id' do
		json = { :format => 'json',  :some_stuff => "val" }
		puts 'before post'
		post "/authorship", json 
		puts 'after post'
		puts response

		response.status.should == 500
	end

end