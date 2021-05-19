# frozen_string_literal: true

describe WebOfScience::QueryAuthor, :vcr do
  subject(:query_author) { described_class.new(author) }

  let(:author) { create :russ_altman }
  let(:author_blank_orcid) { create :russ_altman, :blank_orcid }
  let(:author_blank_name) { create :author, :blank_first_name, :valid_orcid }
  let(:author_blank_name_and_orcid) { create :author, :blank_first_name, :blank_orcid }

  # avoid caching Savon client across examples (affects VCR)
  before { allow(WebOfScience).to receive(:client).and_return(WebOfScience::Client.new(Settings.WOS.AUTH_CODE)) }

  it 'works' do
    expect(query_author).to be_a described_class
  end

  describe '#uids without symbolicTimeSpan' do
    it 'indicates the query is valid' do
      expect(query_author).to be_valid
    end

    it 'returns some Array<String> of WOS-UIDs' do
      # The VCR fixture is > 500 records at the time it was recorded;
      # if the VCR cassette is updated, this value could change
      # and this spec assumes it's only going to get larger
      expect(query_author.uids.count).to be > 480
    end
  end

  describe '#uids with symbolicTimeSpan' do
    subject(:query_author) { described_class.new(author, symbolicTimeSpan: '4week') }

    it 'indicates the query is valid' do
      expect(query_author).to be_valid
    end

    it 'returns less Array<String> of WOS-UIDs' do
      # The VCR fixture is only a few records at the time it was recorded;
      # if the VCR cassette is updated, this value could change anywhere
      # from zero records to ? and this assumes it's not going to be > 100
      expect(query_author.uids.count).to be < 100
    end
  end

  describe '#uids with only the name query valid' do
    subject(:query_blank_orcid) { described_class.new(author_blank_orcid) }

    # The VCR fixture is > 470 records at the time it was recorded;
    # if the VCR cassette is updated, this value could change
    # and this spec assumes it's only going to get larger
    it 'returns some uids' do
      expect(query_blank_orcid).to be_valid
      expect(query_blank_orcid.orcid_query).not_to be_valid
      expect(query_blank_orcid.name_query).to be_valid
      expect(query_blank_orcid.uids.size).to be > 450
    end
  end

  describe '#uids with only the orcid query valid' do
    subject(:query_blank_author) { described_class.new(author_blank_name) }

    # The VCR fixture is ~ 150 records at the time it was recorded;
    # if the VCR cassette is updated, this value could change
    # and this spec assumes it's only going to get larger
    it 'returns some uids' do
      expect(query_blank_author).to be_valid
      expect(query_blank_author.orcid_query).to be_valid
      expect(query_blank_author.name_query).not_to be_valid
      expect(query_blank_author.uids.size).to be > 140
    end
  end

  describe '#uids with both the orcid and name queries invalid' do
    subject(:query_blank_author_and_orcid) { described_class.new(author_blank_name_and_orcid) }

    it 'returns an empty array' do
      expect(query_blank_author_and_orcid).not_to be_valid
      expect(query_blank_author_and_orcid.uids).to be_empty
    end
  end
end
