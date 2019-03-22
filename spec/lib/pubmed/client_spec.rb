describe Pubmed::Client do
  let(:pubmed_client) { described_class.new }

  describe '#fetch_records_for_pmid_list' do
    context 'with valid pmid list of 4' do
      it 'returns a list of 4 pubmed records ' do
        VCR.use_cassette('Pubmed_Client/_fetch_records_for_pmid_list/returns_a_list') do
          expect(Nokogiri::XML(pubmed_client.fetch_records_for_pmid_list([211, 589, 591, 960]))
                   .xpath('//PubmedArticle').size).to eq(4)
        end
      end
    end

    context 'with invalid pmid list' do
      it 'returns an empty array' do
        VCR.use_cassette('Pubmed_Client/_fetch_records_for_pmid_list/returns_an_empty_array') do
          expect(Nokogiri::XML(pubmed_client.fetch_records_for_pmid_list([233_333_333_333_333, 45_555_666_666_666]))
                   .xpath('//PubmedArticle').size).to eq(0)
        end
      end
    end
  end

  describe '#search' do
    let(:term) { 'Altman R[author]' }
    context 'without additional arguments' do
      it 'returns a list of pubmed records' do
        VCR.use_cassette('Pubmed_Client/_search/returns_a_list') do
          expect(Nokogiri::XML(pubmed_client.search(term)).xpath('//IdList/Id').size).to eq(1140)
        end
      end
    end

    context 'with additional arguments' do
      let(:addl_args) { 'reldate=90&datetype=edat' }
      it 'returns a list of pubmed records' do
        VCR.use_cassette('Pubmed_Client/_search/returns_a_smaller_list') do
          expect(Nokogiri::XML(pubmed_client.search(term, addl_args)).xpath('//IdList/Id').size).to eq(7)
        end
      end
    end
  end
end
