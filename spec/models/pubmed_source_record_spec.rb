require 'spec_helper'

describe PubmedSourceRecord, :vcr do
  let(:pmid_created_1999) { 10_000_166 }

  describe '.get_pubmed_record_from_pubmed' do
    it 'returns an instance of PubmedSourceRecord' do
      record = described_class.get_pubmed_record_from_pubmed(pmid_created_1999)
      expect(record).to be_an described_class
    end
    it 'calls PubmedSourceRecord.get_and_store_records_from_pubmed' do
      expect(described_class).to receive(:get_and_store_records_from_pubmed)
      described_class.get_pubmed_record_from_pubmed(pmid_created_1999)
    end
    it 'extracts fields - pmid' do
      record = described_class.get_pubmed_record_from_pubmed(pmid_created_1999)
      expect(record.pmid).to eq pmid_created_1999
    end
  end

  context '.source_as_hash' do
    context 'DOI extraction' do
      def doi(pmid)
        record = described_class.get_pubmed_record_from_pubmed(pmid)
        return nil if record.nil?
        record.source_as_hash[:identifier].find { |id| id[:type] == 'doi' }
      end
      it 'constructs a URL based on the DOI' do
        expect(doi(12_529_422)).to include(url: 'http://dx.doi.org/10.1091/mbc.E02-06-0327')
      end
      context 'extracts from ArticleId' do
        it 'works when ELocationID is missing' do
          expect(doi(12_529_422)).to include(id: '10.1091/mbc.E02-06-0327')
        end
        it 'works when ELocationID is present' do
          expect(doi(23_453_302)).to include(id: '10.1016/j.neunet.2013.01.016')
        end
        it 'works when record is longer than 64kb' do
          expect(doi(26_430_984)).to include(id: '10.1103/PhysRevLett.115.121604')
        end
      end
      context 'extracts from ELocationID' do
        it 'works when ArticleId is missing' do
          expect(doi(26_858_277)).to include(id: '10.1136/bmj.i493')
        end
      end
    end
  end
end
