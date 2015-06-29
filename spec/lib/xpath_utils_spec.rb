require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XpathUtils do
  describe '#regex_reject' do
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
      <ArrayOfPublicationItem>
      XML
      Nokogiri::XML xml
    end

    it 'returns nodes where the passed in regex is not found' do
      nodes = doc.xpath("//PublicationItem[regex_reject(DocumentTypeList, '#{Settings.sw_doc_types_to_skip}')]/PublicationItemID", XpathUtils.new)
      expect(nodes.size).to eq 1
      expect(nodes.first.text).to eq '2'
    end
  end
end
