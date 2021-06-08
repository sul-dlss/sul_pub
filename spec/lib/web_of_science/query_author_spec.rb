# frozen_string_literal: true

describe WebOfScience::QueryAuthor, :vcr do
  subject(:query_author) { described_class.new(author) }

  let(:query_period_author) { described_class.new(period_author) }
  let(:query_space_author) { described_class.new(space_author) }
  let(:query_blank_author) { described_class.new(blank_author) }

  let(:author) { create :russ_altman }
  let(:space_author) { create :author, :space_first_name }
  let(:period_author) { create :author, :period_first_name }
  let(:blank_author) { create :author, :blank_first_name }
  let(:names) { query_author.send(:names) }

  let(:alternate_identity) { create :author_identity } # this creates the associated author as well
  let(:alternate_author_identity) { alternate_identity.author }

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
    subject(:query_author) { described_class.new(author, symbolicTimeSpan: '4week') }

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

    it 'contains author names and institutions' do
      expect(params[:userQuery]).to include(*names, 'stanford')
    end

    context 'update' do
      subject(:query_author) { described_class.new(author, symbolicTimeSpan: '4week') }

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
      expect(names).to include('Altman,Russ')
    end
  end

  describe '#institutions' do
    it 'author institutions includes normalized name' do
      expect(query_author.send(:institutions)).to include('stanford')
    end
  end

  describe '#empty_fields' do
    it 'has collections with empty fields' do
      expect(query_author.send(:empty_fields)).to include(collectionName: String, fieldName: [''])
    end
  end

  describe '#quote_wrap' do
    it 'wraps strings in double quotes' do
      expect(query_author.send(:quote_wrap, %w[a bc def])).to eq %w["a" "bc" "def"]
    end

    it 'deduplicates and removes empties' do
      expect(query_author.send(:quote_wrap, %w[a bc a bc].concat(['']))).to eq %w["a" "bc"]
    end

    it 'removes quotes in a name' do
      expect(query_author.send(:quote_wrap,
                               ['peter', 'peter paul',
                                'peter "paul" mary'])).to eq ['"peter"', '"peter paul"', '"peter paul mary"']
    end
  end

  context 'with a user with valid first names' do
    it 'indicates it is a valid query' do
      expect(query_author).to be_valid
    end
  end

  context 'with a user with no valid first names' do
    it 'indicates that name with a period for a first name is not a valid query' do
      expect(query_period_author).not_to be_valid
    end

    it 'indicates that a name with a space for a first name is not a valid query' do
      expect(query_space_author).not_to be_valid
    end

    it 'indicates that a name with a blank for a first name is not a valid query' do
      expect(query_blank_author).not_to be_valid
    end
  end

  context 'for a single alternate identity' do
    let(:alt_last_name) { alternate_identity.last_name }
    let(:alt_first_name) { alternate_identity.first_name }
    let(:alt_middle_name) { alternate_identity.middle_name }

    describe '#names' do
      context 'with invalid data and ambiguous first name' do
        it 'ignores the bad alternate identity data and first initial variants' do
          alternate_identity.update(first_name: '.', institution: 'Example')
          expect(alternate_author_identity.unique_first_initial?).to be false # because of a non-Stanford alternate identity
          expect(alternate_author_identity.author_identities.first.first_name).to eq '.' # bad first name
          # we do not get the name variant with the period for a first name (i.e. the alternate identity)
          #  nor do we get first initial variants because of the ambiguous first initial
          #  (we would have more if we allowed the bad name variant and the ambiguous first initial)
          expect(described_class.new(alternate_author_identity).send(:names)).to match_array %w[Edler,Alice
                                                                                                Edler,Alice,Jim
                                                                                                Edler,Alice,J]
        end
      end

      context 'with invalid data and non-ambiguous first name' do
        it 'ignores the bad alternate identity data but includes first initial variants' do
          alternate_identity.update(first_name: '.', institution: 'Stanford')
          expect(alternate_author_identity.unique_first_initial?).to be true # because alternate identity is Stanford and unique
          expect(alternate_author_identity.author_identities.first.first_name).to eq '.' # bad first name
          # we do not get the name variant with the period for a first name (i.e. no alternate identity)
          expect(described_class.new(alternate_author_identity).send(:names)).to match_array %w[Edler,Alice
                                                                                                Edler,A
                                                                                                Edler,Alice,Jim
                                                                                                Edler,Alice,J
                                                                                                Edler,AJ
                                                                                                Edler,A,J]
        end
      end

      context 'with valid data and ambiguous first name' do
        it 'ignores the first initial variants' do
          alternate_identity.update(first_name: 'Sam', institution: 'Example')
          expect(alternate_author_identity.unique_first_initial?).to be false # because of a non-Stanford alternate identity
          #  we do not get first initial variants because of the ambiguous first initial
          #  but we do get the other variants with the alternate identity
          #  (we would have more if we allowed the bad name variant and the ambiguous first initial)
          expect(described_class.new(alternate_author_identity).send(:names)).to match_array ['Edler,Alice',
                                                                                              'Edler,Alice,Jim',
                                                                                              'Edler,Alice,J',
                                                                                              "#{alt_last_name},#{alt_first_name}",
                                                                                              "#{alt_last_name},#{alt_first_name},#{alt_middle_name}",
                                                                                              "#{alt_last_name},#{alt_first_name},#{alt_middle_name[0]}"]
        end
      end

      context 'with valid data and non-ambiguous first name' do
        it 'includes all name variants' do
          alternate_identity.update(first_name: 'Alice2', institution: 'Stanford')
          expect(alternate_author_identity.unique_first_initial?).to be true # because alternate identity is Stanford and unique
          # we get all variants with first initials and also the alternate identity
          expect(described_class.new(alternate_author_identity).send(:names)).to match_array ['Edler,Alice',
                                                                                              'Edler,A',
                                                                                              'Edler,Alice,Jim',
                                                                                              'Edler,Alice,J',
                                                                                              'Edler,AJ',
                                                                                              'Edler,A,J',
                                                                                              "#{alt_last_name},#{alt_first_name}",
                                                                                              "#{alt_last_name},#{alt_first_name[0]}",
                                                                                              "#{alt_last_name},#{alt_first_name},#{alt_middle_name}",
                                                                                              "#{alt_last_name},#{alt_first_name},#{alt_middle_name[0]}",
                                                                                              "#{alt_last_name},#{alt_first_name[0]}#{alt_middle_name[0]}",
                                                                                              "#{alt_last_name},#{alt_first_name[0]},#{alt_middle_name[0]}"]
        end
      end
    end
  end
end
