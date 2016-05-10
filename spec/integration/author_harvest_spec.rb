require 'spec_helper'

feature 'Author harvest', 'data-integration': true, type: :controller do
  before do
    Delayed::Worker.delay_jobs = false
    @controller = AuthorsController.new
    expect(controller).to receive(:check_authorization).and_return(true)
  end
  let(:author) { create(:author_russ_altman) }
  ##
  # These tests test the /authors/{cap_profile_id}/harvest endpoint with real
  # Stanford authors.
  scenario 'for an Author without alternate identities' do
    pre_harvest_count = author.publications.count
    post :harvest, cap_profile_id: author.cap_profile_id, format: :json
    post_harvest_count = author.publications.count
    expect(post_harvest_count).to be >= pre_harvest_count
    expect(post_harvest_count).to be_between(500, 600).exclusive # 567 on 2016.05.06
  end
  scenario 'for an Author with alternate identities' do
    pre_harvest_count = author.publications.count
    post :harvest, cap_profile_id: author.cap_profile_id, format: :json, altNames: 'true'
    post_harvest_count = author.publications.count
    expect(post_harvest_count).to be >= pre_harvest_count
    expect(post_harvest_count).to be_between(600, 700).exclusive # 656 on 2016.05.06
  end
end
