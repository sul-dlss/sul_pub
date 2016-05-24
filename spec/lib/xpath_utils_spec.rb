require 'spec_helper'

describe XpathUtils do
  let(:doc) do
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
    <ArrayOfPublicationItem>
    XML
    Nokogiri::XML xml
  end

  describe '#regex_reject' do
    it 'returns nodes where the passed in regex is not found' do
      reject_types = Settings.sw_doc_types_to_skip.join('|')
      nodes = doc.xpath("//PublicationItem[regex_reject(DocumentTypeList, '#{reject_types}')]/PublicationItemID", XpathUtils.new)
      expect(nodes.size).to eq 1
      expect(nodes.first.text).to eq '2'
    end
  end
end
