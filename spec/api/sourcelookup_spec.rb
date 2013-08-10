require 'spec_helper'


describe SulBib::API do
  
  let(:publication_with_test_title) { create :publication, title: "pathological"}
  let(:publication) { create :publication}
  let(:author) {create :author }
  let(:headers) {{ 'HTTP_CAPKEY' => '***REMOVED***', 'CONTENT_TYPE' => 'application/json' }}
  let(:valid_json_for_post) {{title: "some title", year: 1938, author: [{name: "jackson joe"}], authorship: [{sul_author_id: author.id, status: "denied", visibility: "public", featured: true}, ]}.to_json}

  
  

  describe "GET /publications/sourcelookup " do

    it "raises an error without a title" do
      get "/publications/sourcelookup", {},
        {"HTTP_CAPKEY" => '***REMOVED***'}
      expect(response.status).to eq(400)
    end

      it " returns bibjson with metadata section " do 
        get "/publications/sourcelookup?title=pathological&maxrows=2", 
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
        result = JSON.parse(response.body)
      
        result["metadata"].should be
      end

      it " returns bibjson with results section " do 
        pending
        get "/publications/sourcelookup?title=pathological&maxrows=2", 
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
        result = JSON.parse(response.body)
        result["records"].should be
      end

      it " returns bibjson with maxrows number of results  " do 
        pending
        get "/publications/sourcelookup?title=pathological&maxrows=5", 
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
        response.status.should == 200
        JSON.parse(response.body)["records"].length.should be == 5
        
      end

      it "returns results from sciencewire"
      it "returns results from local pubs"
      it "returns combined results from sciencewire and local pubs" do
       
        publication_with_test_title 
        get "/publications/sourcelookup?title=pathological", 
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
          JSON.parse(response.body).should be
      end

      it "returns results that match the requested title"

      it "returns results that match the requested year"
  end

end