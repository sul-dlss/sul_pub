require 'spec_helper'

describe SulBib::API do
  describe "GET /api/v1/statuses" do
    it "returns an empty array of statuses" do
      get "/api/v1/statuses"
      response.status.should == 200
      JSON.parse(response.body).should == []
    end
  end
  describe "GET /api/v1/statuses/:id" do
    it "returns a status by id" do
      status = Status.create!
      get "/api/v1/statuses/#{status.id}"
      response.body.should == status.to_json
    end
  end
end