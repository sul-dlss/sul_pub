require 'spec_helper'

describe "profiles/new" do
  before(:each) do
    assign(:profile, stub_model(Profile,
      :sunetid => "MyString",
      :university_id => 1,
      :shc_doctor_no => 1,
      :ca_license_number => "MyString",
      :cap_first_name => "MyString",
      :cap_last_name => "MyString",
      :cap_middle_name => "MyString",
      :display_name => "MyString",
      :official_first_name => "MyString",
      :official_last_name => "MyString",
      :official_middle_name => "MyString",
      :preferred_first_name => "MyString",
      :preferred_last_name => "MyString",
      :preferred_middle_name => "MyString",
      :pubmed_last_name => "MyString",
      :pubmed_first_initial => "MyString",
      :pubmed_middle_initial => "MyString",
      :pubmed_institution => "MyString",
      :pubmed_other_institution => "MyString",
      :cap_url => "MyString"
    ).as_new_record)
  end

  it "renders new profile form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => profiles_path, :method => "post" do
      assert_select "input#profile_sunetid", :name => "profile[sunetid]"
      assert_select "input#profile_university_id", :name => "profile[university_id]"
      assert_select "input#profile_shc_doctor_no", :name => "profile[shc_doctor_no]"
      assert_select "input#profile_ca_license_number", :name => "profile[ca_license_number]"
      assert_select "input#profile_cap_first_name", :name => "profile[cap_first_name]"
      assert_select "input#profile_cap_last_name", :name => "profile[cap_last_name]"
      assert_select "input#profile_cap_middle_name", :name => "profile[cap_middle_name]"
      assert_select "input#profile_display_name", :name => "profile[display_name]"
      assert_select "input#profile_official_first_name", :name => "profile[official_first_name]"
      assert_select "input#profile_official_last_name", :name => "profile[official_last_name]"
      assert_select "input#profile_official_middle_name", :name => "profile[official_middle_name]"
      assert_select "input#profile_preferred_first_name", :name => "profile[preferred_first_name]"
      assert_select "input#profile_preferred_last_name", :name => "profile[preferred_last_name]"
      assert_select "input#profile_preferred_middle_name", :name => "profile[preferred_middle_name]"
      assert_select "input#profile_pubmed_last_name", :name => "profile[pubmed_last_name]"
      assert_select "input#profile_pubmed_first_initial", :name => "profile[pubmed_first_initial]"
      assert_select "input#profile_pubmed_middle_initial", :name => "profile[pubmed_middle_initial]"
      assert_select "input#profile_pubmed_institution", :name => "profile[pubmed_institution]"
      assert_select "input#profile_pubmed_other_institution", :name => "profile[pubmed_other_institution]"
      assert_select "input#profile_cap_url", :name => "profile[cap_url]"
    end
  end
end
