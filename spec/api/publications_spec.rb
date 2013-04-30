require 'spec_helper'


before do
  @publication1 = FactoryGirl.create!(:publication)
  @publication2 = Publication.build_new_manual_publication(Settings.cap_provenance, FactoryGirl.attributes_for(:publication))
  @publication3 = FactoryGirl.create(:publication) do |pub|
      pub.contributions.create(attributes_for(:contribution))
      pub.publication_identifiers.create(attributes_for(:publication_identifer))
    end
  @publications = [
    @publication1,
    @publication2,
    @publication3
  ]
  @pubs_as_json = [publication1.pub_hash, publication2.pub_hash, publication3.pub_hash].to_json
end

context 'fetching the list of publications' do

  subject do
    get '/publications'
    response.status.should == 200
    JSON.parse(response.body)
  end

  it 'should return a list of publications' do
    should == @pubs_as_json
  end

end


describe SulBib::API do
  
  describe "GET /publications/:id" do
    it "returns a publication by id" do
      publication = FactoryGirl.create(:publication)
      get "/publications/#{publication.id}"
      response.body.should == publication.pub_hash.to_json
    end
  end
end