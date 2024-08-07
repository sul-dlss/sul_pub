# frozen_string_literal: true

describe WebOfScience::QueryName, :vcr do
  subject(:query_name) { described_class.new(author) }

  let(:query_period_author) { described_class.new(period_author) }
  let(:query_space_author) { described_class.new(space_author) }
  let(:query_blank_author) { described_class.new(blank_author) }

  let(:author) { create(:russ_altman) }
  let(:space_author) { create(:author, :space_first_name) }
  let(:period_author) { create(:author, :period_first_name) }
  let(:blank_author) { create(:author, :blank_first_name) }
  let(:names) { query_name.send(:names) }

  it 'works' do
    expect(query_name).to be_a described_class
  end

  describe '#uids without loadTimeSpan' do
    it 'indicates the query is valid' do
      expect(query_name).to be_valid
    end

    it 'returns a large Array<String> of WOS-UIDs' do
      # The VCR fixture is > 470 records at the time it was recorded;
      # if the VCR cassette is updated, this value could change
      # and this spec assumes it's only going to get larger
      expect(query_name.uids.count).to be > 400
    end
  end

  describe '#uids with loadTimeSpan' do
    subject(:query_name) { described_class.new(author, load_time_span: '4W') }

    it 'indicates the query is valid' do
      expect(query_name).to be_valid
    end

    it 'returns a small Array<String> of WOS-UIDs' do
      # The VCR fixture is only 16 records at the time it was recorded;
      # if the VCR cassette is updated, this value could change anywhere
      # from zero records to ? and this assumes it's not going to be > 100
      expect(query_name.uids.count).to be < 100
    end
  end

  # PRIVATE

  describe '#name_query' do
    let(:query) { query_name.send(:name_query) }

    it 'contains author names and institutions' do
      expect(query).to eq('AU=("Altman,Russ" OR "Altman,Russ,Biagio" OR "Altman,Russ,B" OR "Altman,R" OR "Altman,R,B") AND AD=("stanford")')
    end
  end

  describe '#names' do
    #=> "\"Altman,Russ\" or \"Altman,R\" or \"Altman,Russ,Biagio\" or \"Altman,Russ,B\" or \"Altman,R,B\""
    it 'includes all of the name variations, including the preferred last name' do
      expect(names.size).to eq 5
      expect(names).to include('Altman,Russ')
    end
  end

  describe '#author' do
    it 'returns the primary author record' do
      expect(query_name.send(:author)).to eq author
    end
  end

  describe '#institutions' do
    it 'includes normalized name' do
      expect(query_name.send(:institutions)).to include('stanford')
    end
  end

  describe '#quote_wrap' do
    it 'wraps strings in double quotes' do
      expect(query_name.send(:quote_wrap, %w[a bc def])).to eq ['"a"', '"bc"', '"def"']
    end

    it 'deduplicates and removes empties' do
      expect(query_name.send(:quote_wrap, %w[a bc a bc].push(''))).to eq ['"a"', '"bc"']
    end

    it 'removes quotes in a name' do
      expect(query_name.send(:quote_wrap,
                             ['peter', 'peter paul',
                              'peter "paul" mary'])).to eq ['"peter"', '"peter paul"', '"peter paul mary"']
    end
  end

  context 'with a user with valid first names' do
    it 'indicates it is a valid query' do
      expect(query_name).to be_valid
    end
  end

  context 'with a user with no valid first names' do
    it 'indicates that name with a period for a first name is not a valid query' do
      expect(query_period_author).not_to be_valid
    end

    it 'indicates that a name with a space for a first name is not a valid query' do
      expect(query_space_author).not_to be_valid
    end

    it 'indicates that a name with a blank for a first name is not a valid query and returns no uids' do
      expect(query_blank_author).not_to be_valid
      expect(query_blank_author.uids).to be_empty
    end
  end

  context 'for a single alternate identity with invalid data' do
    describe '#names' do
      let(:author_one_identity) { create(:author) }
      let(:bad_alternate_identity) { create(:author_identity) }

      before do
        bad_alternate_identity.update(first_name: '.')
        author_one_identity.author_identities << bad_alternate_identity
      end

      it 'ignores the bad alternate identity data' do
        expect(author_one_identity.author_identities.first.first_name).to eq '.' # bad first name
        # we get three name variants out (we would have more if we allowed the bad name variant)
        expect(described_class.new(author_one_identity).send(:names)).to eq %w[Edler,Alice Edler,Alice,Jim
                                                                               Edler,Alice,J]
      end
    end
  end
end
