require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Author do

  let(:auth_hash) {
    {"active"=>false,
     "authorship"=>
      [{"featured"=>false,
        "status"=>"new",
        "sulPublicationId"=>198465,
        "visibility"=>"public"}],
     "importEnabled"=>false,
     "importSettings"=>
       [{"firstName"=>"Henry", "lastName"=>"Lowe", "middleName"=>"J."},
        {"firstName"=>"H",
         "institution"=>"Stanford University",
         "lastName"=>"Lowe",
         "middleName"=>"J"}],
      "lastModified"=>"2013-08-03T06:12:25.767-07:00",
      "populations"=>["stanford", "som", "shc"],
      "profile"=>
       {"californiaPhysicianLicense"=>"C50735",
        "displayName"=>"Henry J. Lowe, MD",
        "email"=>"hlowe@stanford.edu",
        "meta"=>
         {"etag"=>"17810123",
          "links"=>
           [{"href"=>"http://irt-ppapp-02:12011/cap-api-qa/api/profiles/v1/3810",
             "rel"=>"https://cap.stanford.edu/rel/self"},
            {"href"=>"https://irt-dev.stanford.edu/cap-su-qa/henry-lowe",
             "rel"=>"https://cap.stanford.edu/rel/public"},
            {"href"=>
              "https://irt-dev.stanford.edu/profiles-qa/auth/frdActionServlet?choiceId=facProfile&profileId=3810",
             "rel"=>"https://cap.stanford.edu/rel/intranet"},
            {"href"=>
              "https://irt-dev.stanford.edu/profiles-qa/frdActionServlet?choiceId=printerprofile&profileversion=full&profileId=3810",
             "rel"=>"https://cap.stanford.edu/rel/pdf"}]},
        "names"=>
         {"legal"=>{"firstName"=>"Henry", "lastName"=>"Lowe", "middleName"=>"J"},
          "preferred"=>
           {"firstName"=>"Henry", "lastName"=>"Lowe", "middleName"=>"J."}},
        "profileId"=>3810,
        "uid"=>"hlowe",
        "universityId"=>"09724972"},
      "profileId"=>3810,
      "visibility"=>"public"}
  }

  let(:missing_fields) {
    {"active"=>false,
     "authorship"=>
      [{"featured"=>false,
        "status"=>"new",
        "sulPublicationId"=>198465,
        "visibility"=>"public"}],
     "importEnabled"=>false,
     "importSettings"=>
       [{"firstName"=>"Henry", "lastName"=>"Lowe", "middleName"=>"J."},
        {"firstName"=>"H",
         "institution"=>"Stanford University",
         "lastName"=>"Lowe",
         "middleName"=>"J"}],
      "lastModified"=>"2013-08-03T06:12:25.767-07:00",
      "populations"=>["stanford", "som", "shc"],
      "profile"=>
       {"californiaPhysicianLicense"=>"C50735",
        "displayName"=>"Henry J. Lowe, MD",
        "meta"=>
         {"etag"=>"17810123",
          "links"=>
           [{"href"=>"http://irt-ppapp-02:12011/cap-api-qa/api/profiles/v1/3810",
             "rel"=>"https://cap.stanford.edu/rel/self"},
            {"href"=>"https://irt-dev.stanford.edu/cap-su-qa/henry-lowe",
             "rel"=>"https://cap.stanford.edu/rel/public"},
            {"href"=>
              "https://irt-dev.stanford.edu/profiles-qa/auth/frdActionServlet?choiceId=facProfile&profileId=3810",
             "rel"=>"https://cap.stanford.edu/rel/intranet"},
            {"href"=>
              "https://irt-dev.stanford.edu/profiles-qa/frdActionServlet?choiceId=printerprofile&profileversion=full&profileId=3810",
             "rel"=>"https://cap.stanford.edu/rel/pdf"}]},
        "names"=>
         {"legal"=>{"firstName"=>"Henry", "lastName"=>"Lowe", "middleName"=>"J"},
          "preferred"=>
           {"firstName"=>"Henry", "lastName"=>"Lowe"}},
        "profileId"=>3810,
        "uid"=>"hlowe",
        "universityId"=>"09724972"},
      "profileId"=>3810,
      "visibility"=>"public"}
  }

  describe ".update_from_cap_authorship_profile_hash" do

    it "creates an author from the profile JSON returned from the CAP authorship API" do
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash(auth_hash)
      expect(auth.cap_profile_id).to eq(auth_hash['profileId'])
      expect(auth.cap_last_name).to eq(auth_hash['profile']['names']['preferred']['lastName'])
      expect(auth.sunetid).to eq(auth_hash['profile']['uid'])
      #...
    end

    it "creates an author from a hash with missing fields" do
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash(missing_fields)
      expect(auth.email).to be_blank
      expect(auth.preferred_middle_name).to be_blank
      expect(auth.email).to be_blank
      expect(auth.emails_for_harvest).to be_blank
    end

  end

  describe ".fetch_from_cap_and_create" do

    it "creates an author from the passed in cap profile id" do
      skip "Administrative Systems firewall rules only allow IP-based requests"
      VCR.use_cassette("author_spec_fetch_from_cap_and_create") do
        auth = Author.fetch_from_cap_and_create 3871
        expect(auth.cap_last_name).to eq('Kwon')
      end
    end
  end

  describe "#harvestable?" do

    it "returns true when the author is active and is import_enabled" do
      h = auth_hash
      h['active'] = true
      h['importEnabled'] = true
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash h
      expect(auth).to be_harvestable
    end

    it "returns false when the author is not active or not import_enabled" do
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash auth_hash
      expect(auth).not_to be_harvestable
    end
  end

end