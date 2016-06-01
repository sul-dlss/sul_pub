require 'spec_helper'
SingleCov.covered!

describe ScienceWirePublications do
  let(:array_publication_item_doctypes) do
    xml = <<-XML
    <ArrayOfPublicationItem>
      <PublicationItem>
        <PublicationItemID>1</PublicationItemID>
        <DocumentTypeList>Meeting Abstract</DocumentTypeList>
      </PublicationItem>
      <PublicationItem>
        <PublicationItemID>2</PublicationItemID>
        <DocumentTypeList>Guideline</DocumentTypeList>
      </PublicationItem>
      <PublicationItem>
        <PublicationItemID>3</PublicationItemID>
        <DocumentTypeList>Letter</DocumentTypeList>
      </PublicationItem>
      <PublicationItem>
        <PublicationItemID>4</PublicationItemID>
        <DocumentTypeList>Book Review</DocumentTypeList>
      </PublicationItem>
      <PublicationItem>
        <PublicationItemID>5</PublicationItemID>
        <DocumentTypeList>Comment|Letter</DocumentTypeList>
      </PublicationItem>
      <PublicationItem>
        <PublicationItemID>6</PublicationItemID>
        <DocumentTypeList>Article|Film Review|Article</DocumentTypeList>
      </PublicationItem>
    </ArrayOfPublicationItem>
    XML
    Nokogiri::XML xml
  end

  let(:empty_xml) do
    Nokogiri::XML ''
  end

  let(:array_publication_item_empty) do
    Nokogiri::XML '<ArrayOfPublicationItem/>'
  end

  let(:array_publication_item_xml) do
    xml = File.read Rails.root.join('spec', 'fixtures', 'sciencewire_source_record', 'publication_items.xml')
    Nokogiri::XML xml
  end
  let(:subject) { described_class.new(array_publication_item_xml) }

  describe '#array_of_publication_item' do
    let(:pub_array) { subject.array_of_publication_item }
    it 'is the first element matching xpath: "//ArrayOfPublicationItem"' do
      expect(pub_array).to eq subject.xml_doc.xpath('//ArrayOfPublicationItem').first
    end
    it 'is a Nokogiri::XML::Element with a name "ArrayOfPublicationItem"' do
      expect(pub_array).to be_an Nokogiri::XML::Element
      expect(pub_array.name).to eq 'ArrayOfPublicationItem'
    end
  end

  describe '#count' do
    it 'returns Integer' do
      count = subject.count
      expect(count).to be_an Integer
      expect(count).to eq subject.publication_items.count
      expect(count).to eq 19
    end
  end

  describe '#each' do
    it 'yields ScienceWirePublication items' do
      subject.each {|pub| expect(pub).to be_an ScienceWirePublication }
    end
  end

  describe 'Enumerable mixin' do
    it 'responds to Enumerable.instance_methods' do
      methods = Enumerable.instance_methods
      methods.each {|method| expect(subject).to respond_to(method) }
    end
  end

  describe '#publication_items' do
    it 'returns an Array<ScienceWirePublication>' do
      expect(subject.publication_items).to be_an Array
      pub = subject.publication_items.first
      expect(pub).to be_an ScienceWirePublication
    end
  end

  describe '#filter_publication_items' do
    it 'does not reject documents, in place' do
      # doc_types_reject is Set<String>
      doc_types_reject = Settings.sw_doc_types_to_skip.to_set
      # doc_types_before is Array<Set<String>>, e.g.
      # [ #<Set: {"Poetry"}>, #<Set: {"Book Review"}>, #<Set: {"Article"}>, #<Set: {"Journal Article"}>, #<Set: {"Comment", "Letter"}>]
      doc_types_before = subject.publication_items.map(&:document_type_list).uniq
      doc_types_before.map! { |type| type.split('|').to_set }
      # doc_types_to_reject is Array<Set<String>>, e.g.
      # [#<Set: {"Poetry"}>, #<Set: {"Book Review"}>, ..., #<Set: {"Comment", "Letter"}>]
      doc_types_to_reject = doc_types_before.select { |types| !doc_types_reject.intersection(types).empty? }
      expect(doc_types_to_reject).not_to be_empty
      # doc_types_filtered is Array<Set<String>>, e.g.
      # [#<Set: {"Review"}>, #<Set: {"Article"}>, #<Set: {"Journal Article"}>]
      doc_types_filtered = doc_types_before - doc_types_to_reject
      expect(doc_types_filtered).not_to be_empty
      subject.filter_publication_items
      doc_types_after = subject.publication_items.map(&:document_type_list).uniq
      doc_types_after.map! { |type| type.split('|').to_set }
      expect(doc_types_after).to eq doc_types_before
      expect(doc_types_after - doc_types_filtered).not_to be_empty
    end
    it 'returns publications with acceptable document types' do
      pubs = described_class.new array_publication_item_doctypes
      good_pubs = pubs.filter_publication_items
      expect(good_pubs.size).to eq 1
      pub = good_pubs.first
      expect(pub.publication_item_id).to eq 2
    end
  end

  describe 'remove_document_types' do
    it 'equals values from Settings' do
      reject_types = subject.remove_document_types
      expect(reject_types).to eq Settings.sw_doc_types_to_skip
    end
    it 'can be set to a different set of document types' do
      my_remove_document_types = ['abc', 'def']
      subject.remove_document_types = my_remove_document_types
      reject_types = subject.instance_variable_get('@remove_document_types')
      expect(reject_types).to eq my_remove_document_types
    end
  end

  describe 'Nokogiri cross-checks' do
    let(:pub_array) { subject.xml_doc.xpath('//ArrayOfPublicationItem').first }
    it 'has a root matching "ArrayOfPublicationItem"' do
      expect(pub_array).to eq subject.xml_doc.root
    end
    it 'has PublicationItem children of ArrayOfPublicationItem' do
      subject.xml_doc.xpath('//PublicationItem').each do |item|
        expect(pub_array.children).to include item
      end
    end
  end

  describe '#valid?' do
    it 'is true for a Nokogiri::XML::Document with an <ArrayOfPublicationItem> element' do
      expect(subject.valid?).to be true
    end
    it 'is true for a Nokogiri::XML::Document with an empty <ArrayOfPublicationItem> element' do
      pubs = described_class.new(array_publication_item_empty)
      expect(pubs.valid?).to be true
    end
    it 'is false for a Nokogiri::XML::Document without an <ArrayOfPublicationItem> element' do
      pubs = described_class.new(empty_xml)
      expect(pubs.valid?).to be false
    end
    it 'is false for any other xml_doc' do
      pubs = described_class.new('')
      expect(pubs.valid?).to be false
    end
  end
end
