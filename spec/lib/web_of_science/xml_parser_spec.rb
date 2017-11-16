require 'htmlentities'

describe WebOfScience::XmlParser do
  let(:wos_encoded_record) { File.read('spec/fixtures/wos_client/wos_encoded_record.html') }
  let(:wos_record_encoded) { WebOfScience::Record.new(encoded_record: wos_encoded_record) }

  shared_examples 'it has well formed XML' do
    it 'returns an XML String' do
      expect(xml_result).to be_an String
    end
    it 'returns well formed XML' do
      expect do
        Nokogiri::XML(xml_result) { |config| config.strict.noblanks }
      end.not_to raise_error
    end
    it 'contains no HTML encoding' do
      expect(xml_result).not_to include '&lt;'
    end
  end

  describe '#to_xml' do
    let(:xml_result) { wos_record_encoded.to_xml }

    it_behaves_like 'it has well formed XML'
  end

  describe '#parse' do
    let(:xml_result) { described_class.parse(nil, wos_encoded_record).to_xml }

    it_behaves_like 'it has well formed XML'
  end
end
