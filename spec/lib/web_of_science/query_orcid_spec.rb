# frozen_string_literal: true

describe WebOfScience::QueryOrcid, :vcr do
  subject(:query_orcid) { described_class.new(author) }

  let(:author) { create :russ_altman }
  let(:author_blank_orcid) { create :author, :blank_orcid }

  # avoid caching Savon client across examples (affects VCR)
  before { allow(WebOfScience).to receive(:client).and_return(WebOfScience::Client.new(Settings.WOS.AUTH_CODE)) }

  it 'works' do
    expect(query_orcid).to be_a described_class
  end

  describe '#uids without symbolicTimeSpan' do
    it 'indicates the query is valid' do
      expect(query_orcid).to be_valid
    end

    it 'returns some Array<String> of WOS-UIDs' do
      # The VCR fixture is ~150 records at the time it was recorded;
      # if the VCR cassette is updated, this value could change
      # and this spec assumes it's only going to get larger
      expect(query_orcid.uids.count).to be > 140
    end
  end

  describe '#uids with symbolicTimeSpan' do
    subject(:query_orcid) { described_class.new(author, symbolicTimeSpan: '4week') }

    it 'indicates the query is valid' do
      expect(query_orcid).to be_valid
    end

    it 'returns less Array<String> of WOS-UIDs' do
      # The VCR fixture is only a few records at the time it was recorded;
      # if the VCR cassette is updated, this value could change anywhere
      # from zero records to ? and this assumes it's not going to be > 100
      expect(query_orcid.uids.count).to be < 100
    end
  end

  describe '#uids with an invalid query' do
    subject(:query_no_orcid) { described_class.new(author_blank_orcid) }

    it 'returns an empty array' do
      expect(query_no_orcid).not_to be_valid
      expect(query_no_orcid.uids).to be_empty
    end
  end
end
