describe Pubmed::Harvester do
  let(:harvester) { described_class.new }

  let(:author) { create :russ_altman }

  describe '#process_author' do
    let(:existing_pub) { create :pub_with_pmid_and_pub_identifier }

    context 'when author has existing publications' do
      before do
        allow(Pubmed::QueryAuthor).to receive_message_chain(:new, :pmids).and_return([existing_pub.pmid.to_s])
      end

      it 'removes publications that exists and assigns the author' do
        expect(harvester.process_author(author)).to be_empty
        expect(existing_pub.authors).to include(author)
      end
    end

    context 'when author has new publications' do
      let(:pmid) { '30833575' }
      before do
        allow(Pubmed::QueryAuthor).to receive_message_chain(:new, :pmids).and_return([pmid])
      end

      it 'removes publications that exists and assigns the author' do
        VCR.use_cassette('Pubmed_Harvester/_process_author/when_new_publications') do
          expect(harvester.process_author(author)).to eq([pmid])
        end
        expect(Publication.find_by_pmid_pub_id(pmid).authors).to include(author)
      end
    end

    context 'when author query has too many publications' do
      let(:lotsa_pmids) { Array(1..Settings.PUBMED.max_publications_per_author) }
      before do
        allow(Pubmed::QueryAuthor).to receive_message_chain(:new, :pmids).and_return(lotsa_pmids)
      end

      it 'aborts the harvest and returns no pmids' do
        expect(harvester.process_author(author)).to eq([])
        expect(author.contributions.size).to eq 0
      end
    end
  end
end
