require 'spec_helper'


describe SulBib::API do

  let(:publication_with_test_title) { create :publication, title: "pathological"}
  let(:publication) { create :publication}
  let(:author) {create :author }
  let(:headers) {{ 'HTTP_CAPKEY' => '***REMOVED***', 'CONTENT_TYPE' => 'application/json' }}
  let(:valid_json_for_post) {{title: "some title", year: 1938, author: [{name: "jackson joe"}], authorship: [{sul_author_id: author.id, status: "denied", visibility: "public", featured: true}, ]}.to_json}




  describe "GET /publications/sourcelookup " do

    it "raises an error when title and doi are not sent" do
      get "/publications/sourcelookup", {},
        {"HTTP_CAPKEY" => '***REMOVED***'}
      expect(response.status).to eq(400)
    end

    describe "?doi" do
      it "returns one document " do
        VCR.use_cassette("sourcelookup_spec_doi") do
          get "/publications/sourcelookup?doi=10.1016/j.mcn.2012.03.007",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}

          response.status.should == 200
          result = JSON.parse(response.body)
          result["metadata"]["records"].should == "1"
          result['records'].first['sw_id'].should == '60813767'
        end
      end

      it "does not query sciencewire if there is an existing publication with the doi" do
        ScienceWireClient.any_instance.should_not_receive(:get_pub_by_doi)
        publication.pub_hash = { :identifier => [ { :type => "doi", :id => "10.1016/j.mcn.2012.03.008", :url => "http://dx.doi.org/10.1016/j.mcn.2012.03.008" } ] }
        publication.sync_identifiers_in_pub_hash_to_db

        get "/publications/sourcelookup?doi=10.1016/j.mcn.2012.03.008",
        { format: "json" },
        {"HTTP_CAPKEY" => '***REMOVED***'}

        response.status.should == 200
        result = JSON.parse(response.body)
        result["metadata"]["records"].should == "1"
        result['records'].first['title'].should match /How I learned Rails/
      end
    end

    describe "?pmid" do
      it "returns one document" do
        VCR.use_cassette("sourcelookup_spec_pmid") do
          get "/publications/sourcelookup?pmid=24196758",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}

          response.status.should == 200
          result = JSON.parse(response.body)
          result["metadata"]["records"].should == "1"
          result['records'].first['provenance'] == 'pubmed'
          result['records'].first['chicago_citation'].should =~ /Sittig/
        end
      end


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