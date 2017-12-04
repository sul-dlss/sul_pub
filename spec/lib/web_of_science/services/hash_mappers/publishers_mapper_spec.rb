describe WebOfScience::Services::HashMappers::PublishersMapper do
  let(:wos_encoded_xml) { File.read('spec/fixtures/wos_client/wos_encoded_record.html') }
  let(:wos_record) { WebOfScience::Data::Record.new(encoded_record: wos_encoded_xml) }

  let(:medline_encoded_xml) { File.read('spec/fixtures/wos_client/medline_encoded_record.html') }
  let(:medline_record) { WebOfScience::Data::Record.new(encoded_record: medline_encoded_xml) }

  describe '#new' do
    it 'works' do
      result = described_class.new
      expect(result).to be_an described_class
    end
  end

  shared_examples 'pub_hash' do
    it 'works' do
      expect(pub_hash).to be_an Hash
    end
  end

  shared_examples 'pub_hash_contains_publisher_data' do
    it 'has a publisher' do
      expect(pub_hash[:publisher]).not_to be_nil
    end
    it 'has a city' do
      expect(pub_hash[:city]).not_to be_nil
    end
    it 'has a country' do
      expect(pub_hash[:country]).not_to be_nil
    end
  end

  context 'WOS records' do
    subject(:mapper) { described_class.new }
    let(:pub_hash) { mapper.map_publisher_to_hash(wos_record) }

    it 'works with WOS records' do
      expect(mapper).to be_an described_class
    end
    it_behaves_like 'pub_hash'
    it_behaves_like 'pub_hash_contains_publisher_data'
  end

  context 'MEDLINE records' do
    subject(:mapper) { described_class.new }
    let(:pub_hash) { mapper.map_publisher_to_hash(medline_record) }

    it 'works with MEDLINE records' do
      expect(publisher).to be_an described_class
    end
    it_behaves_like 'pub_hash'
  end
end
