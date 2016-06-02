require 'spec_helper'

feature 'Author harvest', 'data-integration': true, type: :controller do
  before do
    Delayed::Worker.delay_jobs = false
    @controller = AuthorsController.new
    expect(controller).to receive(:check_authorization).and_return(true)
  end
  let(:logger) { Logger.new('log/integration_tests.log') }
  ##
  # This factory depends on a private file in spec/factories/author.local.rb
  # This author has many seed publications and the alternate identies are not
  # VERY different from the author preferred name.  For this author, the
  # suggestion query (or smart search) runs by default; with alt-names enabled,
  # it can supplement results from the publication query (or dumb search).
  let(:author) { create(:author_russ_altman) }
  ##
  # These tests test the /authors/{cap_profile_id}/harvest endpoint with real
  # Stanford authors.
  scenario 'for an Author without alternate identities' do
    pre_harvest_count = author.publications.count
    post :harvest, cap_profile_id: author.cap_profile_id, format: :json
    expect(response.status).to eq 202
    sleep 10 # this is a delayed job API, wait for it to do something
    author.publications.reload
    post_harvest_count = author.publications.count
    logger.info("author_harvest: author=#{author.last_name}, with-alt-names: false, pre: #{pre_harvest_count}, post: #{post_harvest_count}")
    expect(post_harvest_count).to be >= pre_harvest_count
    expect(post_harvest_count).to be_between(500, 600) # 567 on 2016.05.13
  end
  scenario 'for an Author with alternate identities' do
    pre_harvest_count = author.publications.count
    post :harvest, cap_profile_id: author.cap_profile_id, format: :json, altNames: 'true'
    expect(response.status).to eq 202
    sleep 10 # this is a delayed job API, wait for it to do something
    author.publications.reload
    post_harvest_count = author.publications.count
    logger.info("author_harvest: author=#{author.last_name}, with-alt-names: true,  pre: #{pre_harvest_count}, post: #{post_harvest_count}")
    expect(post_harvest_count).to be >= pre_harvest_count
    expect(post_harvest_count).to be_between(500, 600) # 568 on 2016.05.13
  end
end
