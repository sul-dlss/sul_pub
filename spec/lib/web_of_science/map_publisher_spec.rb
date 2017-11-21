describe WebOfScience::MapPublisher do
  let(:wos_encoded_xml) { File.read('spec/fixtures/wos_client/wos_encoded_record.html') }
  let(:wos_record) { WebOfScience::Record.new(encoded_record: wos_encoded_xml) }

  let(:medline_encoded_xml) { File.read('spec/fixtures/wos_client/medline_encoded_record.html') }
  let(:medline_record) { WebOfScience::Record.new(encoded_record: medline_encoded_xml) }

  describe '#new' do
    it 'works with WOS records' do
      result = described_class.new(wos_record)
      expect(result).to be_an described_class
    end
    it 'raises ArgumentError with nil params' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end
    it 'raises ArgumentError with anything other than WebOfScience::Record' do
      expect { described_class.new('could be xml') }.to raise_error(ArgumentError)
    end
  end

  shared_examples 'it_extracts_publishers' do
    describe '#publishers' do
      let(:publishers) { publisher.publishers }

      it 'works' do
        expect(publishers).to be_an Array
      end
      it 'contains publisher information' do
        expect(publishers.first).to be_an Hash
      end
      it 'contains publisher name' do
        expect(publishers.first).to include('full_name' => 'ASSOC COLL RESEARCH LIBRARIES')
      end
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
    let(:publisher) { described_class.new(wos_record) }
    let(:pub_hash) { publisher.pub_hash }

    it 'works with WOS records' do
      expect(publisher).to be_an described_class
    end
    it_behaves_like 'it_extracts_publishers'
    it_behaves_like 'pub_hash'
    it_behaves_like 'pub_hash_contains_publisher_data'
  end

  context 'MEDLINE records' do
    let(:publisher) { described_class.new(medline_record) }
    let(:pub_hash) { publisher.pub_hash }

    it 'works with MEDLINE records' do
      expect(publisher).to be_an described_class
    end
    it_behaves_like 'pub_hash'
    it 'has no publishers' do
      expect(publisher.publishers).to be_empty
    end
  end
end
