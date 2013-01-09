require 'spec_helper'

describe "profiles/index" do
  before(:each) do
    assign(:profiles, [
      stub_model(Profile,
        :sunetid => "Sunetid",
        :university_id => 1,
        :shc_doctor_no => 2,
        :ca_license_number => "Ca License Number",
        :cap_first_name => "Cap First Name",
        :cap_last_name => "Cap Last Name",
        :cap_middle_name => "Cap Middle Name",
        :display_name => "Display Name",
        :official_first_name => "Official First Name",
        :official_last_name => "Official Last Name",
        :official_middle_name => "Official Middle Name",
        :preferred_first_name => "Preferred First Name",
        :preferred_last_name => "Preferred Last Name",
        :preferred_middle_name => "Preferred Middle Name",
        :pubmed_last_name => "Pubmed Last Name",
        :pubmed_first_initial => "Pubmed First Initial",
        :pubmed_middle_initial => "Pubmed Middle Initial",
        :pubmed_institution => "Pubmed Institution",
        :pubmed_other_institution => "Pubmed Other Institution",
        :cap_url => "Cap Url"
      ),
      stub_model(Profile,
        :sunetid => "Sunetid",
        :university_id => 1,
        :shc_doctor_no => 2,
        :ca_license_number => "Ca License Number",
        :cap_first_name => "Cap First Name",
        :cap_last_name => "Cap Last Name",
        :cap_middle_name => "Cap Middle Name",
        :display_name => "Display Name",
        :official_first_name => "Official First Name",
        :official_last_name => "Official Last Name",
        :official_middle_name => "Official Middle Name",
        :preferred_first_name => "Preferred First Name",
        :preferred_last_name => "Preferred Last Name",
        :preferred_middle_name => "Preferred Middle Name",
        :pubmed_last_name => "Pubmed Last Name",
        :pubmed_first_initial => "Pubmed First Initial",
        :pubmed_middle_initial => "Pubmed Middle Initial",
        :pubmed_institution => "Pubmed Institution",
        :pubmed_other_institution => "Pubmed Other Institution",
        :cap_url => "Cap Url"
      )
    ])
  end

  it "renders a list of profiles" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Sunetid".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "Ca License Number".to_s, :count => 2
    assert_select "tr>td", :text => "Cap First Name".to_s, :count => 2
    assert_select "tr>td", :text => "Cap Last Name".to_s, :count => 2
    assert_select "tr>td", :text => "Cap Middle Name".to_s, :count => 2
    assert_select "tr>td", :text => "Display Name".to_s, :count => 2
    assert_select "tr>td", :text => "Official First Name".to_s, :count => 2
    assert_select "tr>td", :text => "Official Last Name".to_s, :count => 2
    assert_select "tr>td", :text => "Official Middle Name".to_s, :count => 2
    assert_select "tr>td", :text => "Preferred First Name".to_s, :count => 2
    assert_select "tr>td", :text => "Preferred Last Name".to_s, :count => 2
    assert_select "tr>td", :text => "Preferred Middle Name".to_s, :count => 2
    assert_select "tr>td", :text => "Pubmed Last Name".to_s, :count => 2
    assert_select "tr>td", :text => "Pubmed First Initial".to_s, :count => 2
    assert_select "tr>td", :text => "Pubmed Middle Initial".to_s, :count => 2
    assert_select "tr>td", :text => "Pubmed Institution".to_s, :count => 2
    assert_select "tr>td", :text => "Pubmed Other Institution".to_s, :count => 2
    assert_select "tr>td", :text => "Cap Url".to_s, :count => 2
  end
end
