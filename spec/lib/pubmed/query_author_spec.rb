describe Pubmed::QueryAuthor do
  let(:query_author) { described_class.new(author, options) }
  let(:query_period_author) { described_class.new(period_author, options) }
  let(:query_space_author) { described_class.new(space_author, options) }

  let(:author) { create :russ_altman }
  let(:space_author) { create :blank_first_name_author }
  let(:period_author) { create :period_first_name_author }

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

    context 'with a user with valid first names' do
      it 'indicates it is a valid query' do
        expect(query_author.send(:'valid?')).to be_truthy
      end
    end

    context 'with a user with no valid first names' do
      it 'indicates that name with a period for a first name is not a valid query' do
        expect(query_period_author.send(:'valid?')).to be_falsey
      end
      it 'indicates that a name with a space for a first name is not a valid query' do
        expect(query_space_author.send(:'valid?')).to be_falsey
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
end
