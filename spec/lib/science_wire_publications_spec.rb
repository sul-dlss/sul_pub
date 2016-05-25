require 'spec_helper'

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

  let(:array_publication_item_xml) do
    xml = File.read Rails.root.join('spec', 'fixtures', 'sciencewire_source_record', 'publication_items.xml')
    Nokogiri::XML xml
  end
  let(:subject) { described_class.new(array_publication_item_xml) }

  describe '#array_of_publication_item' do
    it 'has a root matching "ArrayOfPublicationItem"' do
      pub_array = subject.array_of_publication_item
      expect(pub_array).to eq subject.xml_docs.root
    end
  end

  describe '#document_type_list' do
    it 'returns Array<String>' do
      types = subject.document_type_list
      expect(types).to be_an Array
      expect(types.first).to be_an String
    end
  end

  describe '#publication_item_ids' do
    it 'returns Array<Integer>' do
      ids = subject.publication_item_ids
      expect(ids).to be_an Array
      expect(ids.first).to be_an Integer
    end
  end

  describe '#publication_items' do
    it 'returns a Nokogiri::XML::NodeSet' do
      expect(subject.publication_items).to be_an Nokogiri::XML::NodeSet
    end
    it 'has nodes of PublicationItem elements' do
      element = subject.publication_items.first
      expect(element.name).to eq 'PublicationItem'
    end
  end

  describe '#remove_document_types' do
    it 'calls publication_has_doc_types?' do
      expect(subject).to receive(:publication_has_doc_types?).at_least(:once).and_call_original
      subject.remove_document_types
    end
    it 'does not reject documents, in place' do
      # doc_types_reject is Set<String>
      doc_types_reject = Settings.sw_doc_types_to_skip.to_set
      # doc_types_before is Array<Set<String>>, e.g.
      # [ #<Set: {"Poetry"}>, #<Set: {"Book Review"}>, #<Set: {"Article"}>, #<Set: {"Journal Article"}>, #<Set: {"Comment", "Letter"}>]
      doc_types_before = subject.document_type_list.uniq
      doc_types_before.map! { |type| type.split('|').to_set }
      # doc_types_to_reject is Array<Set<String>>, e.g.
      # [#<Set: {"Poetry"}>, #<Set: {"Book Review"}>, ..., #<Set: {"Comment", "Letter"}>]
      doc_types_to_reject = doc_types_before.select { |types| !doc_types_reject.intersection(types).empty? }
      expect(doc_types_to_reject).not_to be_empty
      # doc_types_filtered is Array<Set<String>>, e.g.
      # [#<Set: {"Review"}>, #<Set: {"Article"}>, #<Set: {"Journal Article"}>]
      doc_types_filtered = doc_types_before - doc_types_to_reject
      expect(doc_types_filtered).not_to be_empty
      subject.remove_document_types
      doc_types_after = subject.document_type_list.uniq
      doc_types_after.map! { |type| type.split('|').to_set }
      expect(doc_types_after).to eq doc_types_before
      expect(doc_types_after - doc_types_filtered).not_to be_empty
    end
    it 'returns publications with acceptable document types' do
      pubs = described_class.new array_publication_item_doctypes
      nodes = pubs.remove_document_types
      expect(nodes.size).to eq 1
      pub_id = nodes.first.at_xpath('PublicationItemID').text
      expect(pub_id).to eq '2'
    end
  end

  describe '#remove_document_types!' do
    it 'calls publication_has_doc_types?' do
      expect(subject).to receive(:publication_has_doc_types?).at_least(:once).and_call_original
      subject.remove_document_types!
    end
    it 'rejects documents, in place' do
      # doc_types_reject is Set<String>
      doc_types_reject = Settings.sw_doc_types_to_skip.to_set
      # doc_types_before is Array<Set<String>>, e.g.
      # [ #<Set: {"Poetry"}>, #<Set: {"Book Review"}>, #<Set: {"Article"}>, #<Set: {"Journal Article"}>, #<Set: {"Comment", "Letter"}>]
      doc_types_before = subject.document_type_list.uniq
      doc_types_before.map! { |type| type.split('|').to_set }
      # doc_types_to_reject is Array<Set<String>>, e.g.
      # [#<Set: {"Poetry"}>, #<Set: {"Book Review"}>, ..., #<Set: {"Comment", "Letter"}>]
      doc_types_to_reject = doc_types_before.select { |types| !doc_types_reject.intersection(types).empty? }
      expect(doc_types_to_reject).not_to be_empty
      # doc_types_filtered is Array<Set<String>>, e.g.
      # [#<Set: {"Review"}>, #<Set: {"Article"}>, #<Set: {"Journal Article"}>]
      doc_types_filtered = doc_types_before - doc_types_to_reject
      expect(doc_types_filtered).not_to be_empty
      pubids_before = subject.publication_item_ids
      subject.remove_document_types!
      pubids_after = subject.publication_item_ids
      expect(pubids_after.count).to be < pubids_before.count
      doc_types_after = subject.document_type_list.uniq
      doc_types_after.map! { |type| type.split('|').to_set }
      expect(doc_types_after).to eq doc_types_filtered
      expect(doc_types_after.count).to be < doc_types_before.count
    end
    it 'returns publications with acceptable document types' do
      pubs = described_class.new array_publication_item_doctypes
      pubs.remove_document_types!
      nodes = pubs.publication_items
      expect(nodes.size).to eq 1
      pub_id = nodes.first.at_xpath('PublicationItemID').text
      expect(pub_id).to eq '2'
    end
  end

  describe '@reject_doc_types' do
    it 'equals values from Settings' do
      reject_types = subject.instance_variable_get('@reject_doc_types')
      expect(reject_types).to eq Settings.sw_doc_types_to_skip
    end
  end

  describe '#select_document_types' do
    it 'returns Array of PublicationItem elements with doc_type' do
      doc_types = ['Article']
      pubs = subject.select_document_types(doc_types)
      expect(pubs).to be_an Array
      expect(pubs.first).to be_an Nokogiri::XML::Element
      expect(pubs.first.name).to eq 'PublicationItem'
      pub_doc_types = pubs.map {|pub| pub.at_xpath('DocumentTypeList').text }
      expect(pub_doc_types.uniq).to eq doc_types
    end
  end

  describe 'Nokogiri cross-checks' do
    it 'has a root matching "ArrayOfPublicationItem"' do
      pub_array = subject.xml_docs.at_xpath('/ArrayOfPublicationItem')
      expect(pub_array).to eq subject.xml_docs.root
    end
    it 'has PublicationItem children of ArrayOfPublicationItem' do
      pub_array = subject.xml_docs.at_xpath('/ArrayOfPublicationItem')
      subject.xml_docs.xpath('//PublicationItem').each do |item|
        expect(pub_array.children).to include item
      end
    end
  end
end
