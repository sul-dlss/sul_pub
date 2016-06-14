require 'spec_helper'
SingleCov.covered!

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

  describe 'instance methods' do
    subject { build_sciencewire_source_record_from_fixture(64_367_696) }

    describe '#publication' do
      it 'returns a ScienceWirePublication' do
        expect(subject.publication).to be_an ScienceWirePublication
      end
      it 'parses the ScienceWire source XML' do
        expect(subject).to receive(:source_data).and_call_original
        subject.publication
      end
    end

    describe '#publication_item' do
      it 'returns a Nokogiri::XML::Element' do
        expect(subject.publication_item).to be_an Nokogiri::XML::Element
      end
      it 'parses the ScienceWire source XML' do
        expect(subject).to receive(:source_data).and_call_original
        subject.publication_item
      end
    end

    describe '#publication_xml' do
      it 'returns a Nokogiri::XML::Document' do
        expect(subject.publication_xml).to be_an Nokogiri::XML::Document
      end
      it 'parses the ScienceWire source XML' do
        expect(subject).to receive(:source_data).and_call_original
        subject.publication_xml
      end
    end
  end

  describe '.source_as_hash' do
    describe 'parses one publication' do
      subject { build_sciencewire_source_record_from_fixture(64_367_696).source_as_hash }
      it 'extracts ids' do
        expect(subject).to include(sw_id: '64367696', pmid: '24213991')
      end
      it 'extracts title' do
        expect(subject[:title]).to eq 'Exploring Patterns of Seafood Provision Revealed in the Global Ocean Health Index'
      end
      it 'extracts author(s)' do
        expect(subject[:author].length).to eq 14
        expect(subject[:author][4]).to include(name: 'Hardy,Darren,')
      end
      it 'extracts abstract' do
        expect(subject[:abstract_restricted]).to start_with 'Sustainable provision of seafood'
      end
      it 'extracts publication' do
        expect(subject).to include(year: '2013',
                                   issn: '0044-7447',
                                   publisher: 'SPRINGER',
                                   city: 'DORDRECHT',
                                   pages: '910-922')
      end
      it 'extracts keywords' do
        expect(subject[:keywords_sw]).to include(*%w(ECOSYSTEMS FISHERIES aquaculture seafood status FAO mariculture assessment fisheries indicator))
      end
      it 'extracts ScienceWire statistics' do
        expect(subject).to include(numberofreferences_sw: '27',
                                   timescited_sw_retricted: '6',
                                   timenotselfcited_sw: '1',
                                   ordinalrank_sw: '1')
      end
      it 'extracts identifiers' do
        expect(subject[:identifier][0]).to include(type: 'PMID', id: '24213991')
        expect(subject[:identifier][1]).to include(type: 'WoSItemID', id: '000326892600002')
        expect(subject[:identifier][2]).to include(type: 'PublicationItemID', id: '64367696')
        expect(subject[:identifier][3]).to include(type: 'doi', id: '10.1007/s13280-013-0447-x')
      end
    end

    describe 'parses one journal article publication' do
      subject { build_sciencewire_source_record_from_fixture(64_367_696).source_as_hash }
      it 'extracts type' do
        expect(subject).to include(type: 'article', documentcategory_sw: 'Journal Document')
        expect(subject[:documenttypes_sw]).to include('Article')
      end
      it 'extracts metadata for an article' do
        expect(subject[:journal]).to include(name: 'AMBIO',
                                             volume: '42',
                                             issue: '8',
                                             pages: '910-922')
        expect(subject[:journal][:articlenumber]).to be_nil
        expect(subject[:journal][:identifier][0]).to include(type: 'issn', id: '0044-7447')
        expect(subject[:journal][:identifier][1]).to include(type: 'doi', id: '10.1007/s13280-013-0447-x')
      end
    end

    describe 'parses one "other" article publication' do
      subject { build_sciencewire_source_record_from_fixture(42_711_944).source_as_hash }
      it 'extracts type' do
        expect(subject).to include(type: 'article', documentcategory_sw: 'Other')
        expect(subject[:documenttypes_sw]).to include('Congresses', 'Journal Article')
      end
      it 'extracts metadata for an article' do
        expect(subject[:journal]).to include(name: 'Nature structural biology',
                                             volume: '6',
                                             issue: '2',
                                             pages: '108-111')
        expect(subject[:journal][:identifier][0]).to include(type: 'issn', id: '1072-8368')
      end
    end

    describe 'parses one book publication' do
      it 'extracts type'
      it 'extracts metadata for a book'
    end
    describe 'parses one inproceedings publication' do
      subject { build_sciencewire_source_record_from_fixture(9_538_214).source_as_hash }
      it 'extracts type' do
        expect(subject).to include(type: 'inproceedings',
                                   documentcategory_sw: 'Conference Proceeding Document')
        expect(subject[:documenttypes_sw]).to include('Article')
      end
      it 'extracts publication source' do # called because Issue is not blank
        expect(subject[:journal]).to include(name: 'INTERNATIONAL JOURNAL OF MEDICAL INFORMATICS',
                                             volume: '51',
                                             issue: '2-3',
                                             pages: '107-116')
      end
      it 'extracts metadata for a paper in proceedings' do
        expect(subject[:conference]).to include(name: '3rd Annual General Meeting of HEALNet',
                                                startdate: '1997-11-01T00:00:00',
                                                enddate: '',
                                                statecountry: 'CANADA')
        expect(subject[:conference][:city]).to be_nil
      end
    end
  end
end
