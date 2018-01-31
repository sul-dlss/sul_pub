# http://savonrb.com/version2/testing.html
# require the helper module
require 'savon/mock/spec_helper'

describe WebOfScience::QueryAuthor do
  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  subject(:query_author) { described_class.new(author) }

  let(:names) { query_author.send(:names) }
  let(:institution) { query_author.send(:institution) }

  # These wos_uids are in the wos_search_author_query_response.xml
  let(:wos_uids) { %w[MEDLINE:29218869 WOS:000422723300003] }
  let(:wos_search_author_query_response) { File.read('spec/fixtures/wos_client/wos_search_author_query_response.xml') }

  let(:author) do
    # public data from
    # - https://stanfordwho.stanford.edu
    # - https://med.stanford.edu/profiles/russ-altman
    author = FactoryBot.create(:author,
                                 preferred_first_name: 'Russ',
                                 preferred_last_name: 'Altman',
                                 preferred_middle_name: 'Biagio',
                                 email: 'Russ.Altman@stanford.edu',
                                 cap_import_enabled: true)
    # create some `author.alternative_identities`
    FactoryBot.create(:author_identity,
                       author: author,
                       first_name: 'R',
                       middle_name: 'B',
                       last_name: 'Altman',
                       email: nil,
                       institution: 'Stanford University')
    FactoryBot.create(:author_identity,
                       author: author,
                       first_name: 'Russ',
                       middle_name: nil,
                       last_name: 'Altman',
                       email: nil,
                       institution: nil)
    author
  end

  it 'works' do
    expect(query_author).to be_a described_class
  end

  describe '#uids' do
    let(:wos_auth_response) { File.read('spec/fixtures/wos_client/authenticate.xml') }

    before do
      wos_client = WebOfScience::Client.new('secret')
      allow(WebOfScience).to receive(:client).and_return(wos_client)
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_search_author_query_response)
    end

    it 'returns an Array<String> of WOS-UIDs' do
      expect(query_author.uids).to eq wos_uids
    end
  end

  # PRIVATE

  describe '#author_query' do
    let(:query) { query_author.send(:author_query) }
    let(:params) { query[:queryParameters] }

    it 'contains query parameters' do
      expect(query).to include(queryParameters: Hash)
      expect(params).to include(databaseId: String, userQuery: String, timeSpan: Hash, queryLanguage: String)
    end

    it 'contains author name' do
      expect(params[:userQuery]).to include(names)
    end

    it 'contains author institution' do
      expect(params[:userQuery]).to include(institution)
    end

    it 'contains timeSpan' do
      expect(params[:timeSpan]).to include(begin: String, end: String)
    end

    it 'uses settings to determine the timeSpan when Settings.WOS.AUTHOR_UPDATE > 0' do
      settings = double
      expect(settings).to receive(:AUTHOR_UPDATE).and_return(30).at_least(:once)
      expect(settings).to receive(:ACCEPTED_DBS).and_return(%w[WOS MEDLINE])
      expect(Settings).to receive(:WOS).and_return(settings).at_least(:once)
      # Try to put Dr Who out of a job so this spec might work
      now = Time.zone.now
      allow(Time.zone).to receive(:now).and_return(now)
      start = (now - Settings.WOS.AUTHOR_UPDATE.days).strftime('%Y-%m-%d')
      stop = now.strftime('%Y-%m-%d')
      expect(params[:timeSpan]).to eq(begin: start, end: stop)
    end

    it 'uses a default timeSpan when Settings.WOS.AUTHOR_UPDATE <= 0' do
      settings = double
      expect(settings).to receive(:AUTHOR_UPDATE).and_return(0).at_least(:once)
      expect(settings).to receive(:ACCEPTED_DBS).and_return(%w[WOS MEDLINE])
      expect(Settings).to receive(:WOS).and_return(settings).at_least(:once)
      # Try to put Dr Who out of a job so this spec might work
      now = Time.zone.now
      allow(Time.zone).to receive(:now).and_return(now)
      start = WebOfScience::Queries::START_DATE # default start date
      stop = now.strftime('%Y-%m-%d')
      expect(params[:timeSpan]).to eq(begin: start, end: stop)
    end
  end

  describe '#names' do
    #=> "\"Altman,Russ\" or \"Altman,R\" or \"Altman,Russ,Biagio\" or \"Altman,Russ,B\" or \"Altman,R,B\""
    it 'author name includes the preferred last name' do
      expect(Agent::AuthorName).to receive(:new).and_call_original
      expect(names).to include(author.preferred_last_name)
    end
  end

  describe '#institution' do
    it 'author institution is a normalized name' do
      expect(Agent::AuthorInstitution).to receive(:new).and_call_original
      expect(institution).to eq 'stanford'
    end
  end

  describe '#empty_fields' do
    let(:fields) { query_author.send(:empty_fields) }

    it 'has collections with empty fields' do
      expect(fields).to include(collectionName: String, fieldName: [''])
    end
  end
end
