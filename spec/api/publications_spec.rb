require 'spec_helper'

describe SulBib::API do
  describe "GET /publications" do
    it "returns an empty bibjson collection" do
      pending "sort out how to check the bibjson response"
      get "/publications"
      
      JSON.parse(response.body).should == []
    end
  end
  
  describe "GET /publications/:id" do
    it "returns a publication by id" do
      publication = FactoryGirl.create(:publication)

      get "/publications/#{publication.id}", 
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
      response.status.should == 200
      response.body.should == publication.pub_hash.to_json
    end
  end


end