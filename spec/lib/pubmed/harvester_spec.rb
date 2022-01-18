# frozen_string_literal: true

describe Pubmed::Harvester do
  let(:harvester) { described_class.new }
  let(:author) { create :russ_altman }

  before do
    allow(Pubmed::QueryAuthor).to receive(:new).with(author, {}).and_return(query_author)
  end

  describe '#process_author' do
    let(:existing_pub) { create :pub_with_pmid_and_pub_identifier }

    context 'when author has existing publications' do
      let(:query_author) { instance_double(Pubmed::QueryAuthor, valid?: true, pmids: [existing_pub.pmid.to_s]) }

      it 'removes publications that exists and assigns the author' do
        expect(harvester.process_author(author)).to be_empty
        expect(existing_pub.authors).to include(author)
      end
    end

    context 'when author has new publications' do
      let(:pmid) { '30833575' }
      let(:query_author) { instance_double(Pubmed::QueryAuthor, valid?: true, pmids: [pmid]) }

      it 'removes publications that exists and assigns the author' do
        VCR.use_cassette('Pubmed_Harvester/_process_author/when_new_publications') do
          expect(harvester.process_author(author)).to eq([pmid])
        end
        expect(Publication.find_by_pmid_pub_id(pmid).authors).to include(author)
      end
    end

    context 'when author query has too many publications' do
      let(:lotsa_pmids) { Array(1..Settings.PUBMED.max_publications_per_author) }
      let(:query_author) { instance_double(Pubmed::QueryAuthor, valid?: true, pmids: lotsa_pmids) }

      it 'aborts the harvest and returns no pmids' do
        expect(NotificationManager).to receive(:error).with(
          ::Harvester::Error,
          "Pubmed::Harvester - Pubmed harvest returned more than #{Settings.PUBMED.max_publications_per_author} " \
          "publications for author id #{author.id} and was aborted",
          harvester
        )
        expect(harvester.process_author(author)).to eq([])
        expect(author.contributions.size).to eq 0
      end
    end

    context 'when author query is invalid' do
      let(:query_author) { instance_double(Pubmed::QueryAuthor, valid?: false) }

      it 'aborts the harvest and returns no pmids' do
        expect(NotificationManager).to receive(:error).with(
          ::Harvester::Error,
          "Pubmed::Harvester - An invalid author query was detected for author id #{author.id} and was aborted",
          harvester
        )
        expect(harvester.process_author(author)).to eq([])
        expect(author.contributions.size).to eq 0
      end
    end
  end
end
