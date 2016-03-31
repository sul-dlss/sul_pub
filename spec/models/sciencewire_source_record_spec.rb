require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SciencewireSourceRecord do
  describe '.lookup_sw_doc_type' do
    it 'maps document types to CAP inproceedings' do
      expect(SciencewireSourceRecord.lookup_sw_doc_type(['Meeting Abstract'])).to eq('inproceedings')
    end

    it 'maps document types to CAP books' do
      expect(SciencewireSourceRecord.lookup_sw_doc_type(['Government Publications'])).to eq('book')
    end

    it 'uses case insensitive string comparisons' do
      expect(SciencewireSourceRecord.lookup_sw_doc_type(['consensus Development Conference nih'])).to eq('inproceedings')
    end

    it 'can take a single string as a parameter' do
      expect(SciencewireSourceRecord.lookup_sw_doc_type(['Meeting Abstract'])).to eq('inproceedings')
    end

    it 'defaults to article' do
      expect(SciencewireSourceRecord.lookup_sw_doc_type('Congresses')).to eq('inproceedings')
    end
  end

  describe '.lookup_cap_doc_type_by_sw_doc_category' do
    it "maps DocumentCategory='Conference Proceeding Document' to cap type of 'inproceedings'" do
      expect(SciencewireSourceRecord.lookup_cap_doc_type_by_sw_doc_category('Conference Proceeding Document')).to eq('inproceedings')
    end

    it "maps DocumentCategory='Journal Document' to cap type of 'article'" do
      expect(SciencewireSourceRecord.lookup_sw_doc_type('Journal Document')).to eq('article')
    end

    it 'defaults to article' do
      expect(SciencewireSourceRecord.lookup_sw_doc_type('Other')).to eq('article')
    end
  end
end
