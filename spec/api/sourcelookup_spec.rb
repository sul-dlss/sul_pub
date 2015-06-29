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

          expect(response.status).to eq(200)
          result = JSON.parse(response.body)
          expect(result["metadata"]["records"]).to eq("1")
          expect(result['records'].first['sw_id']).to eq('60813767')
        end
      end

      it "does not query sciencewire if there is an existing publication with the doi" do
        VCR.use_cassette("sourcelookup_spec_doi_local_manual_found") do
          publication.pub_hash = { :identifier => [ { :type => "doi", :id => "10.1016/j.mcn.2012.03.008", :url => "http://dx.doi.org/10.1016/j.mcn.2012.03.008" } ] }
          publication.sync_identifiers_in_pub_hash_to_db

          get "/publications/sourcelookup?doi=10.1016/j.mcn.2012.03.008",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}

          expect(response.status).to eq(200)
          result = JSON.parse(response.body)
          expect(result["metadata"]["records"]).to eq("1")
          expect(result['records'].first['title']).to match /Protein kinase C alpha/i
          expect(result['records'].first['provenance']).to match /sciencewire/
        end
      end
    end

    describe "?pmid" do
      it "returns one document" do
        VCR.use_cassette("sourcelookup_spec_pmid") do
          get "/publications/sourcelookup?pmid=24196758",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}

          expect(response.status).to eq(200)
          result = JSON.parse(response.body)
          expect(result["metadata"]["records"]).to eq("1")
          result['records'].first['provenance'] == 'pubmed'
          expect(result['records'].first['chicago_citation']).to match(/Sittig/)
        end
      end


    end

      it " returns bibjson with metadata section " do
        get "/publications/sourcelookup?title=pathological&maxrows=2",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
        result = JSON.parse(response.body)

        expect(result["metadata"]).to be
      end

      it " returns bibjson with results section " do
        skip
        get "/publications/sourcelookup?title=pathological&maxrows=2",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
        result = JSON.parse(response.body)
        expect(result["records"]).to be
      end

      it " returns bibjson with maxrows number of results  " do
        skip
        get "/publications/sourcelookup?title=pathological&maxrows=5",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["records"].length).to eq(5)

      end

      it "returns results from sciencewire"
      it "returns results from local pubs"
      it "returns combined results from sciencewire and local pubs" do

        publication_with_test_title
        get "/publications/sourcelookup?title=pathological",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
          expect(JSON.parse(response.body)).to be
      end

      it "returns results that match the requested title"

      it "returns results that match the requested year"
  end

end