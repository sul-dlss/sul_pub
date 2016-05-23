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
end
