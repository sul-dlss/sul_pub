require 'spec_helper'


describe SulBib::API do

  let(:publication) { FactoryGirl.create :publication }
  let!(:publication_with_contributions) { create :publication_with_contributions, contributions_count:2  }
  let(:publication_list) { create_list(:contribution, 15, visibility: "public", status: "approved") }
  let(:author) {FactoryGirl.create :author }
  let(:author_with_sw_pubs) {create :author_with_sw_pubs}
  let(:headers) {{ 'HTTP_CAPKEY' => '***REMOVED***', 'CONTENT_TYPE' => 'application/json' }}
  let(:valid_json_for_post) {{title: "some title", year: 1938, issn: '32242424', pages: '34-56', author: [{name: "jackson joe"}], authorship: [{sul_author_id: author.id, status: "denied", visibility: "public", featured: true} ]}.to_json}
  let(:invalid_json_for_post) {{title: "some title", year: 1938, issn: '32242424', pages: '34-56', author: [{name: "jackson joe"}]}.to_json}
  let(:json_with_new_author) {{title: "some title", year: 1938, issn: '32242424', pages: '34-56', author: [{name: "henry lowe"}], authorship: [{cap_profile_id: '3810', status: "denied", visibility: "public", featured: true} ]}.to_json}
  let(:json_with_isbn) { <<-JSON
    {"abstract":"","abstract_restricted":"","allAuthors":"author A, author B","author":[{"firstname":"John ","lastname":"Doe","middlename":"","name":"Doe  John ","role":"author"},{"firstname":"Raj","lastname":"Kathopalli","middlename":"","name":"Kathopalli  Raj","role":"author"}],"authorship":[{"cap_profile_id":#{author.cap_profile_id},"featured":true,"status":"APPROVED","visibility":"PUBLIC"}],"booktitle":"TEST Book I","edition":"2","etal":true,"identifier":[{"id":"1177188188181","type":"isbn"},{"type":"doi","url":"18819910019"}],"last_updated":"2013-08-10T21:03Z","provenance":"CAP","publisher":"Publisher","series":{"number":"919","title":"Series 1","volume":"1"},"type":"book","year":"2010"}
   JSON
  }
  let(:json_with_isbn_changed_doi) { <<-JSON
    {"abstract":"","abstract_restricted":"","allAuthors":"author A, author B","author":[{"firstname":"John ","lastname":"Doe","middlename":"","name":"Doe  John ","role":"author"},{"firstname":"Raj","lastname":"Kathopalli","middlename":"","name":"Kathopalli  Raj","role":"author"}],"authorship":[{"cap_profile_id":#{author.cap_profile_id},"featured":true,"status":"APPROVED","visibility":"PUBLIC"}],"booktitle":"TEST Book I","edition":"2","etal":true,"identifier":[{"id":"1177188188181","type":"isbn"},{"type":"doi","url":"18819910019-updated"},{"type":"SULPubId","id":"164","url":"http://sulcap.stanford.edu/publications/164"}],"last_updated":"2013-08-10T21:03Z","provenance":"CAP","publisher":"Publisher","series":{"number":"919","title":"Series 1","volume":"1"},"type":"book","year":"2010"}
   JSON
  }
  let(:json_with_isbn_deleted_doi) { <<-JSON
    {"abstract":"","abstract_restricted":"","allAuthors":"author A, author B","author":[{"firstname":"John ","lastname":"Doe","middlename":"","name":"Doe  John ","role":"author"},{"firstname":"Raj","lastname":"Kathopalli","middlename":"","name":"Kathopalli  Raj","role":"author"}],"authorship":[{"cap_profile_id":#{author.cap_profile_id},"featured":true,"status":"APPROVED","visibility":"PUBLIC"}],"booktitle":"TEST Book I","edition":"2","etal":true,"identifier":[{"id":"1177188188181","type":"isbn"},{"type":"SULPubId","id":"164","url":"http://sulcap.stanford.edu/publications/164"}],"last_updated":"2013-08-10T21:03Z","provenance":"CAP","publisher":"Publisher","series":{"number":"919","title":"Series 1","volume":"1"},"type":"book","year":"2010"}
   JSON
    }
  describe "POST /publications" do

    context "when valid post" do

      it "should respond with 200" do
        post "/publications", valid_json_for_post, headers
        response.status.should == 201
      end

      it " returns bibjson from the pub_hash for the new publication" do
        post "/publications", valid_json_for_post, headers
          response.body.should == Publication.last.pub_hash.to_json
      end

      it 'creates a new contributions record in the db' do
        post "/publications", valid_json_for_post, headers
        Contribution.where(publication_id: Publication.last.id, author_id: author.id).first.status.should == 'denied'
      end

      it 'increases number of contribution records by one' do
        #puts valid_json_for_post
        expect {
            post "/publications", valid_json_for_post, headers
          }.to change(Contribution, :count).by(1)
      end

      it 'increases number of publication records by one' do
        expect {
            post "/publications", valid_json_for_post, headers
          }.to change(Publication, :count).by(1)
      end

      it 'increases number of publication manual source records by one' do
        expect {
            post "/publications", valid_json_for_post, headers
          }.to change(Publication, :count).by(1)
      end


      it "creates an appropriate publication record from the posted bibjson" do
        post "/publications", valid_json_for_post, headers
        response.status.should == 201
        pub = Publication.last

        parsed_outgoing_json = JSON.parse(valid_json_for_post)

        expect(pub.title).to eq(parsed_outgoing_json["title"])
        expect(pub.year).to eq(parsed_outgoing_json["year"])
        expect(pub.pages).to eq(parsed_outgoing_json["pages"])
        expect(pub.issn).to eq(parsed_outgoing_json["issn"])

      end

      it "creates a matching pub_hash in the publication record from the posted bibjson" do
        post "/publications", valid_json_for_post, headers
        response.status.should == 201
        pub_hash = Publication.last.reload.pub_hash

        parsed_outgoing_json = JSON.parse(response.body)

        expect(pub_hash[:author]).to eq(parsed_outgoing_json["author"])
        expect(pub_hash[:authorship][0][:visibility]).to eq(parsed_outgoing_json["authorship"][0]["visibility"])
        expect(pub_hash[:authorship][0][:status]).to eq(parsed_outgoing_json["authorship"][0]["status"])
        expect(pub_hash[:authorship][0][:featured]).to eq(parsed_outgoing_json["authorship"][0]["featured"])
        expect(pub_hash[:authorship][0][:cap_profile_id]).to eq(parsed_outgoing_json["authorship"][0]["cap_profile_id"])

      end

      it " creates a pub with matching authorship info in hash and contributions table" do
        post "/publications", valid_json_for_post, headers
        response.status.should == 201
        pub = Publication.last
        parsed_outgoing_json = JSON.parse(response.body)
        contrib = Contribution.where(publication_id: pub.id, author_id: author.id).first
        expect(contrib.visibility).to eq(parsed_outgoing_json["authorship"][0]["visibility"])
        expect(contrib.status).to eq(parsed_outgoing_json["authorship"][0]["status"])
        expect(contrib.featured).to eq(parsed_outgoing_json["authorship"][0]["featured"])
        expect(contrib.cap_profile_id).to eq(parsed_outgoing_json["authorship"][0]["cap_profile_id"])
      end

      it "does not duplicate SULPubIds" do

        json_with_sul_pub_id = { :identifier => [ { :type => "SULPubId", :id => "n", :url => "m" } ], authorship: [{sul_author_id: author.id, status: "denied", visibility: "public", featured: true}] }.to_json

        post "/publications", json_with_sul_pub_id, headers
        response.status.should == 201
        parsed_outgoing_json = JSON.parse(response.body)

        expect(parsed_outgoing_json['identifier'].select { |x| x['type'] == "SULPubId"}).to have(1).item
        expect(parsed_outgoing_json['identifier'][0]['id']).to_not eq("n")
      end

      it "creates a pub with with isbn" do
        post "/publications", json_with_isbn, headers
        response.status.should == 201
        pub = Publication.last.reload
        parsed_outgoing_json = JSON.parse(response.body)
        expect(parsed_outgoing_json['identifier']).to include({"id"=>"1177188188181", "type"=>"isbn"})
        expect(parsed_outgoing_json['identifier']).to include({"type"=>"doi","url"=>"18819910019"})
        expect(parsed_outgoing_json['identifier']).to include({"type"=>"SULPubId","url"=>"http://sulcap.stanford.edu/publications/#{pub.id}","id"=>"#{pub.id}"})
        expect(parsed_outgoing_json['identifier'].size).to eq(3)
        expect(pub.publication_identifiers).to have(2).items
        expect(pub.publication_identifiers.map { |x| x.identifier_type }).to include("doi", "isbn")
        expect(response.body).to eq(pub.pub_hash.to_json)
      end

    end # end of the context

    context "updating record" do
      it "should not duplicate SULPubIDs" do

        json_with_sul_pub_id = { :identifier => [ { :type => "SULPubId", :id => "n", :url => "m" } ], authorship: [{sul_author_id: author.id, status: "denied", visibility: "public", featured: true}] }.to_json

        put "/publications/#{publication.id}", json_with_sul_pub_id, headers
        response.status.should == 200
        parsed_outgoing_json = JSON.parse(response.body)

        expect(parsed_outgoing_json['identifier'].select { |x| x['type'] == "SULPubId"}).to have(1).item
        expect(parsed_outgoing_json['identifier'][0]['id']).to_not eq("n")
      end
    end

    context "when valid post" do

        it " returns 302 for duplicate pub" do
          post "/publications", valid_json_for_post, headers
          response.status.should == 201
          post "/publications", valid_json_for_post, headers
          response.status.should == 302
        end

        it " returns 406 - Not Acceptable for  bibjson without an authorship entry" do
          post "/publications", invalid_json_for_post, headers
          response.status.should == 406
        end

        it "creates an Author when a new cap_profile_id is passed in" do
          VCR.use_cassette("api_publications_spec_create_new_auth") do
            post "/publications", json_with_new_author, headers
            response.status.should == 201

            auth = Author.where(:cap_profile_id => '3810').first
            auth.cap_last_name.should == 'Lowe'
          end
        end
    end
  end  # end of the describe

  describe "PUT /publications/:id" do

    it "updates an existing pub " do
      post "/publications", json_with_isbn, headers
      id = Publication.last.id
      put "/publications/#{id}", json_with_isbn_changed_doi, headers
      parsed_outgoing_json = JSON.parse(response.body)
      expect(parsed_outgoing_json['identifier']).to include({"id"=>"1177188188181", "type"=>"isbn"})
      expect(parsed_outgoing_json['identifier']).to include({"type"=>"doi","url"=>"18819910019-updated"})
      expect(parsed_outgoing_json['identifier']).to include({"type"=>"SULPubId","url"=>"http://sulcap.stanford.edu/publications/#{id}","id"=>"#{id}"})
      expect(parsed_outgoing_json['identifier'].size).to eq(3)
    end

    it "deletes an identifier from the db if it is not in the incoming json" do
      post "/publications", json_with_isbn, headers
      id = Publication.last.id
      put "/publications/#{id}", json_with_isbn_deleted_doi, headers
      parsed_outgoing_json = JSON.parse(response.body)
      expect(parsed_outgoing_json['identifier']).to include({"id"=>"1177188188181", "type"=>"isbn"})
      expect(parsed_outgoing_json['identifier']).to include({"type"=>"SULPubId","url"=>"http://sulcap.stanford.edu/publications/#{id}","id"=>"#{id}"})
      expect(parsed_outgoing_json['identifier'].size).to eq(2)
    end

  end



  describe "GET /publications/:id" do
    it " returns 200 for valid call " do
        get "/publications/#{publication.id}",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
      response.status.should == 200
    end
    it "returns a publication bibjson doc by id" do
      publication
      get "/publications/#{publication.id}",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
      response.body.should == publication.pub_hash.to_json
    end

    it "returns a pub with valid bibjson for sw harvested records" do
      author_with_sw_pubs
      ScienceWireHarvester.new.harvest_pubs_for_author_ids([33])
      new_pub = Publication.last
       get "/publications/#{new_pub.id}",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
       response.status.should == 200
       response.body.should == new_pub.pub_hash.to_json
       result = JSON.parse(response.body)
       #puts result
       #result["provenance"].should == "sciencewire"
    end


    it "returns only those pubs changed since specified date"
    it "returns only those pubs with contributions for the given author"
    it "returns only pubs with a cap active profile"

    context "when pub id doesn't exist" do
      it "returns not found code" do
        get "/publications/88888888888",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
        response.status.should == 404
      end
    end

  end # end of the describe

  describe "GET /publications" do

    context "with no params specified" do
      it "returns first page" do
        get "/publications/",
            { format: "json" },
            {"HTTP_CAPKEY" => '***REMOVED***'}
        result = JSON.parse(response.body)
        result["metadata"]["page"].should == 1
        JSON.parse(response.body)["records"].should be
      end

    end # end of context

    context "when there are 150 records" do


      it "should be an error if a capkey isn't provided" do
        publication_list
        get "/publications?page=1&per=7",
            { format: "json" }
        response.status.should == 403
      end

      it "returns a one page collection of 100 bibjson records when no paging is specified" do
        publication_list
        get "/publications?page=1&per=7",
          { format: "json" },
          {"HTTP_CAPKEY" => '***REMOVED***'}
        response.status.should == 200
        expect(response.headers['Content-Type']).to be =~ /application\/json/

        result = JSON.parse(response.body)

        result["metadata"]["records"].should == "7"
        result["metadata"]["page"].should == 1
        result["records"][2]["author"].should be
      end

      it "should filter by active authors" do
        publication_list
        get "/publications?page=1&per=1&capActive=true",
            { format: "json" },
            {"HTTP_CAPKEY" => '***REMOVED***'}
        response.status.should == 200
        result = JSON.parse(response.body)
        result["metadata"]["records"].should == "1"
        result["metadata"]["page"].should == 1
      end


      it "should paginate by active authors" do
        publication_list
        get "/publications?page=2&per=1&capActive=true",
            { format: "json" },
            {"HTTP_CAPKEY" => '***REMOVED***'}
        response.status.should == 200
        result = JSON.parse(response.body)
        result["metadata"]["records"].should == "1"
        result["metadata"]["page"].should == 2

      end
    end # end of context

  end # end of the describe




end