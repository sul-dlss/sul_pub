RSpec.describe WebOfScienceSourceRecord, type: :model do
  subject(:wos_src_rec) { described_class.new(source_data: wos_record.to_xml) }

  let(:encoded_records) { File.read('spec/fixtures/wos_client/wos_encoded_records.html') }
  let(:wos_record) { WebOfScience::Records.new(encoded_records: encoded_records).first }

  context 'initialize a new record' do
    it 'cannot be created without a WOS source record' do
      expect { described_class.new }.to raise_error(RuntimeError)
    end
    it 'extracts attributes' do
      expect(wos_src_rec.uid).to eq 'WOS:A1972N549400003'
      expect(wos_src_rec.database).to eq 'WOS'
      expect(wos_src_rec.source_fingerprint).to eq 'e5088910f3e61f73eebaa4c8938c742989259f3821f2a050de57475e7f385445'
      expect(wos_src_rec).to be_active
    end
  end

  context 'sets identifiers' do
    before do
      identifiers = WebOfScience::Identifiers.new(wos_record)
      allow(identifiers).to receive(:doi).and_return('doi')
      allow(identifiers).to receive(:pmid).and_return('123')
      allow(WebOfScience::Identifiers).to receive(:new).and_return(identifiers)
    end
    it 'sets attributes' do
      expect(wos_src_rec.doi).to eq 'doi'
      expect(wos_src_rec.pmid).to eq 123
    end
    it 'allows select' do
      wos_src_rec.save!
      expect(described_class.select(:doi).first).to be_a described_class
      expect(described_class.select(:pmid).first).to be_a described_class
      expect(described_class.select(:id).first).to be_a described_class
    end
  end

  context 'source record validation' do
    it 'works' do
      expect(wos_src_rec).to be_valid
      expect { wos_src_rec.save! }.not_to raise_error
    end
  end

  context 'utility methods' do
    it 'has a Nokogiri::XML::Document' do
      expect(wos_src_rec.doc).to be_a Nokogiri::XML::Document
    end
    it 'has a WebOfScience::Record' do
      expect(wos_src_rec.record).to be_a WebOfScience::Record
    end
    it 'has an XML String' do
      expect(wos_src_rec.to_xml).to be_a String
    end
    it 'an XML String from the doc utility matches the source_data' do
      # TODO: use equivalent_xml
      expect(wos_src_rec.to_xml).to eq wos_src_rec.source_data
    end
  end
end
