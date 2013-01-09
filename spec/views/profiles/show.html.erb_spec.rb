require 'spec_helper'

describe "profiles/show" do
  before(:each) do
    @profile = assign(:profile, stub_model(Profile,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Sunetid/)
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/Ca License Number/)
    rendered.should match(/Cap First Name/)
    rendered.should match(/Cap Last Name/)
    rendered.should match(/Cap Middle Name/)
    rendered.should match(/Display Name/)
    rendered.should match(/Official First Name/)
    rendered.should match(/Official Last Name/)
    rendered.should match(/Official Middle Name/)
    rendered.should match(/Preferred First Name/)
    rendered.should match(/Preferred Last Name/)
    rendered.should match(/Preferred Middle Name/)
    rendered.should match(/Pubmed Last Name/)
    rendered.should match(/Pubmed First Initial/)
    rendered.should match(/Pubmed Middle Initial/)
    rendered.should match(/Pubmed Institution/)
    rendered.should match(/Pubmed Other Institution/)
    rendered.should match(/Cap Url/)
  end
end
