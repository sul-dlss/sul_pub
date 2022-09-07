# frozen_string_literal: true

describe Pubmed::QueryAuthor do
  let(:query_author) { described_class.new(author, options) }
  let(:author) { create :russ_altman }

  let(:options) { {} }

  describe '#pmids' do
    context 'with a user with alternate identities' do
      let(:pmids) { query_author.pmids }

      it 'generates the correct term string' do
        VCR.use_cassette('Pubmed_QueryAuthor/_pmids/returns_a_list') do
          expect(pmids.length).to eq(336)
          expect(pmids[0]).to eq('31051039')
        end
      end
    end

    context 'with a user with alternate identities and limited by date' do
      let(:options) { { reldate: 90 } }

      let(:pmids) { query_author.pmids }

      it 'generates the correct term string' do
        VCR.use_cassette('Pubmed_QueryAuthor/_pmids/returns_a_smaller_list') do
          expect(pmids.length).to eq(4)
          expect(pmids[0]).to eq('31051039')
        end
      end
    end
  end

  describe '#term_for_author' do
    context 'with a user with alternate identities' do
      it 'generates the correct term string' do
        expect(query_author.send(:term)).to eq('((Altman, Russ[Author]) OR (Altman, R[Author])) AND (Stanford University[Affiliation])')
      end
    end

    context 'with a user with alternate identities with different institutions' do
      before do
        AuthorIdentity.create(
          author: author,
          first_name: 'R',
          middle_name: 'B',
          last_name: 'Altman',
          institution: 'Amherst College'
        )
      end

      it 'generates the correct term string' do
        expect(query_author.send(:term)).to eq('((Altman, Russ[Author]) OR (Altman, R[Author])) AND (Stanford University[Affiliation] OR Amherst College[Affiliation])')
      end
    end

    context 'with a user with alternate identities with different institutions with an & with a trailing and a leading space' do
      before do
        AuthorIdentity.create(
          author: author,
          first_name: 'R',
          middle_name: 'B',
          last_name: 'Altman',
          institution: 'William & Mary'
        )
      end

      it 'generates the correct term string' do
        expect(query_author.send(:term)).to eq('((Altman, Russ[Author]) OR (Altman, R[Author])) AND (Stanford University[Affiliation] OR William and Mary[Affiliation])')
      end
    end

    context 'with a user with alternate identities with different institutions with an & without any surrounding spaces' do
      before do
        AuthorIdentity.create(
          author: author,
          first_name: 'R',
          middle_name: 'B',
          last_name: 'Altman',
          institution: 'Texas A&M'
        )
      end

      it 'generates the correct term string' do
        expect(query_author.send(:term)).to eq('((Altman, Russ[Author]) OR (Altman, R[Author])) AND (Stanford University[Affiliation] OR Texas AandM[Affiliation])')
      end
    end

    context 'with a user with alternate identities with different institutions with an & with just a trailing space' do
      before do
        AuthorIdentity.create(
          author: author,
          first_name: 'R',
          middle_name: 'B',
          last_name: 'Altman',
          institution: 'Texas A& M'
        )
      end

      it 'generates the correct term string' do
        expect(query_author.send(:term)).to eq('((Altman, Russ[Author]) OR (Altman, R[Author])) AND (Stanford University[Affiliation] OR Texas Aand M[Affiliation])')
      end
    end

    context 'with a user with alternate identities with different institutions with an & with just a leading space' do
      before do
        AuthorIdentity.create(
          author: author,
          first_name: 'R',
          middle_name: 'B',
          last_name: 'Altman',
          institution: 'Texas A &M'
        )
      end

      it 'generates the correct term string' do
        expect(query_author.send(:term)).to eq('((Altman, Russ[Author]) OR (Altman, R[Author])) AND (Stanford University[Affiliation] OR Texas A andM[Affiliation])')
      end
    end

    context 'with a user with just a period for first name' do
      before do
        AuthorIdentity.create(
          author: author,
          first_name: '.',
          middle_name: 'B',
          last_name: 'Altman',
          institution: 'Texas A &M'
        )
      end

      it 'generates the correct term string' do
        expect(query_author.send(:term)).to eq('((Altman, Russ[Author]) OR (Altman, R[Author])) AND (Stanford University[Affiliation] OR Texas A andM[Affiliation])')
      end
    end

    context 'with a user with no first name' do
      before do
        AuthorIdentity.create(
          author: author,
          first_name: '',
          middle_name: 'B',
          last_name: 'Altman',
          institution: 'Texas A &M'
        )
      end

      it 'generates the correct term string' do
        expect(query_author.send(:term)).to eq('((Altman, Russ[Author]) OR (Altman, R[Author])) AND (Stanford University[Affiliation] OR Texas A andM[Affiliation])')
      end
    end

    context 'with a nil first name' do
      before do
        AuthorIdentity.create(
          author: author,
          first_name: nil,
          middle_name: 'B',
          last_name: 'Altman',
          institution: 'Texas A &M'
        )
      end

      it 'generates the correct term string' do
        expect(query_author.send(:term)).to eq('((Altman, Russ[Author]) OR (Altman, R[Author])) AND (Stanford University[Affiliation] OR Texas A andM[Affiliation])')
      end
    end
  end

  describe '#valid?' do
    let(:query_period_author) { described_class.new(period_author, options) }
    let(:query_space_author) { described_class.new(space_author, options) }
    let(:query_blank_author) { described_class.new(blank_author, options) }
    let(:query_or_author) { described_class.new(or_author, options) }
    let(:query_not_author) { described_class.new(not_author, options) }
    let(:query_nil_author_first_name) { described_class.new(nil_author_first_name, options) }
    let(:query_nil_author_last_name) { described_class.new(nil_author_last_name, options) }
    let(:query_author_only_one_bad_name) { described_class.new(author_one_bad_name, options) }

    let(:space_author) { create :author, :space_first_name }
    let(:period_author) { create :author, :period_first_name }
    let(:blank_author) { create :author, :blank_first_name }
    let(:or_author) { create :author, :or_first_name }
    let(:not_author) { create :author, :not_last_name }
    let(:nil_author_first_name) { create :author, :nil_first_name }
    let(:nil_author_last_name) { create :author, :nil_last_name }
    let(:author_one_bad_name) { create :author_with_alternate_identities, :or_first_name }

    context 'with a user with valid first names' do
      it 'indicates it is a valid query' do
        expect(query_author).to be_valid
      end
    end

    context 'with a user with one invalid name and a second valid name' do
      it 'indicates it is a valid query, ignoring the bad name in the query' do
        expect(query_author_only_one_bad_name).to be_valid
        expect(query_author_only_one_bad_name.send(:term)).to eq("((#{author_one_bad_name.author_identities.first.last_name}, #{author_one_bad_name.author_identities.first.first_name}[Author])) AND (Stanford University[Affiliation] OR Example University[Affiliation])")
      end
    end

    context 'with a user with no valid names' do
      it 'indicates that name with a period for a first name is not a valid query' do
        expect(query_period_author).not_to be_valid
      end

      it 'indicates that a name with a space for a first name is not a valid query' do
        expect(query_space_author).not_to be_valid
      end

      it 'indicates that a name with a blank for a first name is not a valid query and returns no pmids' do
        expect(query_blank_author).not_to be_valid
        expect(query_blank_author.pmids).to be_empty
      end

      it 'indicates that a name with nil as a first name is not a valid query' do
        expect(query_nil_author_first_name).not_to be_valid
      end

      it 'indicates that a name with nil as a last name is not a valid query' do
        expect(query_nil_author_last_name).not_to be_valid
      end

      it 'indicates that a name with "Or" as a first name is not a valid query and returns no pmids' do
        expect(query_or_author).not_to be_valid
        expect(query_or_author.pmids).to be_empty
      end

      it 'indicates that a name with "Not" as a last name is not a valid query and returns no pmids' do
        expect(query_not_author).not_to be_valid
        expect(query_not_author.pmids).to be_empty
      end
    end
  end
end
