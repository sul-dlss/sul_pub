require 'spec_helper'
SingleCov.covered!

describe ScienceWirePublication do
  let(:wrong_element) do
    xml_doc = Nokogiri::XML '<NotPublicationItem/>'
    xml_doc.xpath('NotPublicationItem').first
  end

  let(:publication_item_empty) do
    xml_doc = Nokogiri::XML '<PublicationItem/>'
    xml_doc.xpath('PublicationItem').first
  end

  let(:publication_item_xml) { File.read Rails.root.join('spec', 'fixtures', 'sciencewire_source_record', 'publication_item.xml') }
  let(:publication_item_doc) { Nokogiri::XML publication_item_xml }
  let(:publication_item_element) do
    publication_item_doc.xpath('PublicationItem').first
  end

  let(:subject) do
    described_class.new(publication_item_element)
  end

  describe '#initialize' do
    it 'accepts a Nokogiri::XML::Element' do
      expect(subject.xml_doc).to be_an Nokogiri::XML::Element
    end
    it 'sets @xml_doc to be the first <PublicationItem> element' do
      pub = described_class.new(publication_item_element)
      item = pub.instance_variable_get('@xml_doc')
      expect(item).to be_an Nokogiri::XML::Element
      expect(item.name).to eq 'PublicationItem'
    end
    it 'raises ArgumentError unless given a <PublicationItem> Nokogiri::XML::Element' do
      expect{ described_class.new(wrong_element) }.to raise_error(ArgumentError)
    end
    it 'raises ArgumentError unless given a Nokogiri::XML::Element' do
      expect{ described_class.new('') }.to raise_error(ArgumentError)
    end
  end

  describe '#doi' do
    it 'returns a String' do
      expect(subject.doi).to be_an String
    end
    it 'returns a valid DOI' do
      expect(subject.doi).to eq '10.1038/447638a'
    end
  end

  describe '#publication_item_id' do
    it 'returns a Integer' do
      expect(subject.publication_item_id).to be_an Integer
    end
    it 'returns a valid Integer' do
      expect(subject.publication_item_id).to eq 75_299_710
    end
  end

  describe '#pmid' do
    it 'returns a Integer' do
      expect(subject.pmid).to be_an Integer
    end
    it 'returns a valid Integer' do
      expect(subject.pmid).to eq 99_999_999
    end
  end

  describe '#wos_item_id' do
    it 'returns a String' do
      expect(subject.wos_item_id).to be_an String
    end
    it 'returns a valid WoSItemID' do
      expect(subject.wos_item_id).to eq '000371236403656'
    end
  end

  describe '#obsolete?' do
    it 'returns true when <IsObsolete> is "true"' do
      xml_doc = subject.xml_doc
      xml_doc.at_xpath('//PublicationItem/IsObsolete').children = 'true'
      expect(subject.obsolete?).to be true
    end
    it 'returns false when <IsObsolete> is "false"' do
      xml_doc = subject.xml_doc
      xml_doc.at_xpath('//PublicationItem/IsObsolete').children = 'false'
      expect(subject.obsolete?).to be false
    end
  end

  describe '#new_publication_item_id' do
    it 'returns a Integer' do
      expect(subject.new_publication_item_id).to be_an Integer
    end
    it 'returns a valid Integer' do
      expect(subject.new_publication_item_id).to eq 0 # for this fixture
    end
  end

  describe '#document_type_list' do
    it 'returns a String' do
      expect(subject.document_type_list).to be_an String
    end
    it 'returns a valid DocumentTypeList' do
      expect(subject.document_type_list).to include 'Journal Article' # for this fixture
    end
  end

  describe '#document_types' do
    it 'returns an Array<String>' do
      expect(subject.document_types).to be_an Array
      expect(subject.document_types.first).to be_an String
    end
    it 'returns a valid DocumentTypeList Array' do
      expect(subject.document_types).to include 'Journal Article' # for this fixture
    end
  end

  describe '#doc_type?' do
    it 'returns true given an Array of matching DocumentType values' do
      expect(subject.doc_type?(['Journal Article'])).to be true
    end
    it 'returns false given an Array of non-matching DocumentType values' do
      expect(subject.doc_type?(['NoDocTypeMatch'])).to be false
    end
    it 'returns false given an empty Array' do
      expect(subject.doc_type?([])).to be false
    end
  end

  describe 'Nokogiri cross-checks' do
    it 'has a name matching "PublicationItem"' do
      expect(subject.xml_doc.name).to eq 'PublicationItem'
    end
  end

  describe 'sorting' do
    it 'sorts by publication_item_id' do
      xml_docA = Nokogiri::XML publication_item_xml
      xml_docB = Nokogiri::XML publication_item_xml
      elementA = xml_docA.xpath('PublicationItem').first
      elementB = xml_docB.xpath('PublicationItem').first
      pubA = described_class.new(elementA)
      pubB = described_class.new(elementB)
      elementB.at_xpath('PublicationItemID').children = (pubB.publication_item_id + 1).to_s
      expect([pubB, pubA].sort).to eq [pubA, pubB]
      ids_before = [pubB, pubA].map(&:publication_item_id)
      ids_sorted = [pubB, pubA].sort.map(&:publication_item_id)
      expect(ids_before).to eq [75_299_711, 75_299_710]
      expect(ids_sorted).to eq [75_299_710, 75_299_711]
    end
  end

  describe '#valid?' do
    it 'is true for a Nokogiri::XML::Element that is a <PublicationItem> element' do
      expect(subject.valid?).to be true
    end
    it 'is true for a Nokogiri::XML::Element that is an empty <PublicationItem> element' do
      pub = described_class.new(publication_item_empty)
      expect(pub.valid?).to be true
    end
  end
end
