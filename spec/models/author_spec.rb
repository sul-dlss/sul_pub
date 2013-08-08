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
      auth.cap_profile_id.should == auth_hash['profileId']
      auth.cap_last_name.should == auth_hash['profile']['names']['preferred']['lastName']
      auth.sunetid.should == auth_hash['profile']['uid']
      #...
    end

    it "creates an author froma hash with missing fields" do
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash(missing_fields)
      auth.email.should be_blank
      auth.preferred_middle_name.should be_blank
      auth.email.should be_blank
      auth.emails_for_harvest.should be_blank
    end

  end

  describe ".fetch_from_cap_and_create" do

    it "creates an author from the passed in cap profile id" do
      VCR.use_cassette("author_spec_fetch_from_cap_and_create") do
        auth = Author.fetch_from_cap_and_create 3871
        auth.cap_last_name.should == 'Kwon'
      end
    end
  end

end