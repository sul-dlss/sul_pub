require 'spec_helper'

describe SulBib::API do
  
 
  describe "POST /authorship" do
    it "adds the authorship entry to the pub_hash for the publication" do
      publication = FactoryGirl.create(:publication)
      author = FactoryGirl.create(:author)
      json_for_post = {sul_author_id: author.id, status: "denied", sul_pub_id: publication.id}.to_json
      headers = { 'HTTP_CAPKEY' => '***REMOVED***', 'CONTENT_TYPE' => 'application/json' }
     # contribution = FactoryGirl.create(:contribution, publication: publication, author: author)
     # header 'CAPKEY', '***REMOVED***'
   #   request.env["HTTP_CAPKEY"] = "***REMOVED***"
      post "/authorship", json_for_post, headers
      response.status.should == 201
     # response.body.should == publication.pub_hash.to_json
     publication.reload
     publication.pub_hash[:authorship].any? { |entry| entry[:sul_author_id] == author.id }.should be_true
    end

    it 'creates a new authorship record in the db' do
      publication = FactoryGirl.create(:publication)
      author = FactoryGirl.create(:author)
     json_for_post = {sul_author_id: author.id, status: "denied", sul_pub_id: publication.id}.to_json
      headers = { 'HTTP_CAPKEY' => '***REMOVED***', 'CONTENT_TYPE' => 'application/json' }
      post "/authorship", json_for_post, headers
           # {"HTTP_CAPKEY" => '***REMOVED***'}
      response.status.should == 201
      Contribution.where(publication_id: publication.id, author_id: author.id).first.status.should == 'denied'
     end

    it 'creates a new authorship record without overwriting existing authorship records'

    it 'increases number of contribution records by one' do
      publication = FactoryGirl.create(:publication)
      author = FactoryGirl.create(:author)
      json_for_post = {sul_author_id: author.id, status: "denied", sul_pub_id: publication.id}.to_json
      headers = { 'HTTP_CAPKEY' => '***REMOVED***', 'CONTENT_TYPE' => 'application/json' }
      expect {
          post "/authorship", json_for_post, headers
        }.to change(Contribution, :count).by(1)
    end
  end 
end

