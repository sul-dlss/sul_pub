describe WebOfScience::QueryAuthor, :vcr do
  subject(:query_author) { described_class.new(author) }

  let(:author) { create :russ_altman }
  let(:names) { query_author.send(:names) }
  let(:institution) { query_author.send(:institution) }

  # avoid caching Savon client across examples (affects VCR)
  before { allow(WebOfScience).to receive(:client).and_return(WebOfScience::Client.new(Settings.WOS.AUTH_CODE)) }

  it 'works' do
    expect(query_author).to be_a described_class
  end

  describe '#uids without symbolicTimeSpan' do
    it 'returns a large Array<String> of WOS-UIDs' do
      # The VCR fixture is 471 records at the time it was recorded;
      # if the VCR cassette is updated, this value could change
      # and this spec assumes it's only going to get larger
      expect(query_author.uids.count).to be > 400
    end
  end

  describe '#uids with symbolicTimeSpan' do
    subject(:query_author) { described_class.new(author, update: true) }

    it 'returns a small Array<String> of WOS-UIDs' do
      # The VCR fixture is only 16 records at the time it was recorded;
      # if the VCR cassette is updated, this value could change anywhere
      # from zero records to ? and this assumes it's not going to be > 100
      expect(query_author.uids.count).to be < 100
    end
  end

  # PRIVATE

  describe '#author_query' do
    let(:query) { query_author.send(:author_query) }
    let(:params) { query[:queryParameters] }

    it 'contains query parameters' do
      expect(query).to include(queryParameters: Hash)
      expect(params).to include(databaseId: String, userQuery: String, queryLanguage: String)
    end

    it 'contains author name' do
      expect(params[:userQuery]).to include(names)
    end

    it 'contains author institution' do
      expect(params[:userQuery]).to include(institution)
    end

    context 'update' do
      subject(:query_author) { described_class.new(author, update: true) }

      it 'uses options to set a symbolicTimeSpan' do
        # to use symbolicTimeSpan, timeSpan must be omitted
        expect(params[:timeSpan]).to be_nil
        expect(params).to include(symbolicTimeSpan: '4week')
      end
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
