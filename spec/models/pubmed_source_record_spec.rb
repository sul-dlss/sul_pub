# frozen_string_literal: true

describe PubmedSourceRecord, :vcr do
  let(:pmid_created_1999) { 10_000_166 }

  describe '#get_pubmed_record_from_pubmed' do
    it 'returns an instance of PubmedSourceRecord' do
      record = described_class.send(:get_pubmed_record_from_pubmed, pmid_created_1999)
      expect(record).to be_an described_class
    end

    it 'returns nil if pubmed lookup is disabled' do
      allow(Settings.PUBMED).to receive(:lookup_enabled).and_return(false)
      record = described_class.send(:get_pubmed_record_from_pubmed, pmid_created_1999)
      expect(record).to be_nil
    end

    it 'calls PubmedSourceRecord.get_and_store_records_from_pubmed' do
      expect(described_class).to receive(:get_and_store_records_from_pubmed)
      described_class.send(:get_pubmed_record_from_pubmed, pmid_created_1999)
    end

    it 'extracts fields - pmid' do
      record = described_class.send(:get_pubmed_record_from_pubmed, pmid_created_1999)
      expect(record.pmid).to eq pmid_created_1999
    end
  end

  describe '#pubmed_update' do
    it 'updates the :source_data field' do
      source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><PMID Version="1">1</PMID><OriginalData/></PubmedArticle>'
      new_source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><PMID Version="1">1</PMID><SomeNewData/></PubmedArticle>'
      pubmed_record = described_class.create(pmid: pmid_created_1999, source_data:)
      allow(described_class).to receive(:find_by_pmid).with(pmid_created_1999).and_return(pubmed_record)
      expect(pubmed_record.source_data).to be_equivalent_to source_data
      allow_any_instance_of(Pubmed::Client).to receive(:fetch_records_for_pmid_list).with(pmid_created_1999).and_return(new_source_data)
      expect(pubmed_record.pubmed_update).to be true
      expect(pubmed_record.source_data).to be_equivalent_to new_source_data
    end

    it 'does not update the :source_data field if no pubmed record is found' do
      source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><PMID Version="1">1</PMID><OriginalData/></PubmedArticle>'
      new_source_data = '<?xml version="1.0" ?><!DOCTYPE PubmedArticleSet PUBLIC "-//NLM//DTD PubMedArticle, 1st January 2017//EN" "https://dtd.nlm.nih.gov/ncbi/pubmed/out/pubmed_170101.dtd"><PubmedArticleSet></PubmedArticleSet>'
      pubmed_record = described_class.create(pmid: pmid_created_1999, source_data:)
      allow(described_class).to receive(:find_by_pmid).with(pmid_created_1999).and_return(pubmed_record)
      expect(pubmed_record.source_data).to be_equivalent_to source_data
      allow_any_instance_of(Pubmed::Client).to receive(:fetch_records_for_pmid_list).with(pmid_created_1999).and_return(new_source_data)
      expect(pubmed_record.pubmed_update).to be false
      expect(pubmed_record.source_data).to be_equivalent_to source_data
    end
  end

  describe '#source_as_hash' do
    it 'returns a pub_hash' do
      record = described_class.send(:get_pubmed_record_from_pubmed, pmid_created_1999)
      expect(record.source_as_hash).to eq(
        { provenance: 'pubmed', pmid: '10000166',
          title: 'Fluid permeability in porous media: Comparison of electrical estimates with hydrodynamical calculations.',
          author: [
            { firstname: 'S', lastname: 'Kostek' },
            { firstname: 'L', middlename: 'M', lastname: 'Schwartz' },
            { firstname: 'D', middlename: 'L', lastname: 'Johnson' }
          ],
          year: '1992',
          date: '1992-01-01',
          type: 'article',
          country: 'United States',
          pages: '186-195',
          issn: '0163-1829',
          journal:
              { name: 'Physical review. B, Condensed matter',
                volume: '45',
                issue: '1',
                identifier: [{ type: 'issn', id: '0163-1829', url: 'http://searchworks.stanford.edu/?search_field=advanced&number=0163-1829' }] },
          identifier: [
            { type: 'PMID', id: '10000166', url: 'https://www.ncbi.nlm.nih.gov/pubmed/10000166' },
            { type: 'doi', id: '10.1103/physrevb.45.186', url: 'https://doi.org/10.1103/physrevb.45.186' }
          ] }
      )
    end
  end
end
