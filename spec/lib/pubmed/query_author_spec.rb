describe Pubmed::QueryAuthor do
  let(:query_author) { described_class.new(author, options) }

  let(:author) { create :russ_altman }

  let(:options) { {} }

  describe '#pmids' do
    context 'with a user with alternate identities' do
      let(:pmids) { query_author.pmids }

      it 'generates the correct term string' do
        VCR.use_cassette('Pubmed_QueryAuthor/_pmids/returns_a_list') do
          expect(pmids.length).to eq(334)
          expect(pmids[0]).to eq('30833575')
        end
      end
    end

    context 'with a user with alternate identities and limited by date' do
      let(:options) { { reldate: 90 } }

      let(:pmids) { query_author.pmids }

      it 'generates the correct term string' do
        VCR.use_cassette('Pubmed_QueryAuthor/_pmids/returns_a_smaller_list') do
          expect(pmids.length).to eq(4)
          expect(pmids[0]).to eq('30833575')
        end
      end
    end
  end

  describe '#term_for_author' do
    context 'with a user with alternate identities' do
      it 'generates the correct term string' do
        expect(query_author.send(:term)).to eq('((Altman Russ[Author]) OR (Altman R[Author])) AND (Stanford University[Affiliation])')
      end
    end
  end
end
