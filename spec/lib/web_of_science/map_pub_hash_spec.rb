describe WebOfScience::MapPubHash do
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

  shared_examples 'pub_hash' do
    it 'works' do
      expect(pub_hash).to be_an Hash
    end
    it 'has "wos" provenance' do
      expect(pub_hash[:provenance]).to eq 'wos'
    end
  end

  shared_examples 'contains_summary_data' do
    xit 'has an abstract' do
      expect(pub_hash[:abstract]).not_to be_nil
    end
    it 'has an authors' do
      expect(pub_hash[:author]).not_to be_nil
    end
    it 'has an authorcount' do
      expect(pub_hash[:authorcount]).not_to be_nil
    end
    it 'has an doc type' do
      expect(pub_hash[:type]).not_to be_nil
    end
    it 'has an identifiers' do
      expect(pub_hash[:identifier]).not_to be_nil
    end
  end

  shared_examples 'contains_publisher_data' do
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

  shared_examples 'common_citation_data' do
    it 'has an year' do
      expect(pub_hash[:year]).not_to be_nil
    end
    it 'has an date' do
      expect(pub_hash[:date]).not_to be_nil
    end
    it 'has an pages' do
      expect(pub_hash[:pages]).not_to be_nil
    end
    it 'has an title' do
      expect(pub_hash[:title]).not_to be_nil
    end
    it 'has an journal' do
      expect(pub_hash[:journal]).not_to be_nil
    end
  end

  context 'WOS records' do
    let(:pub_hash_class) { described_class.new(wos_record) }
    let(:pub_hash) { pub_hash_class.pub_hash }

    it 'works with WOS records' do
      expect(pub_hash_class).to be_an described_class
    end
    it_behaves_like 'pub_hash'
    it_behaves_like 'common_citation_data'
    it_behaves_like 'contains_publisher_data'
    it_behaves_like 'contains_summary_data'
  end

  context 'MEDLINE records' do
    let(:pub_hash_class) { described_class.new(medline_record) }
    let(:pub_hash) { pub_hash_class.pub_hash }

    it 'works with MEDLINE records' do
      expect(pub_hash_class).to be_an described_class
    end
    it_behaves_like 'pub_hash'
    it_behaves_like 'common_citation_data'
    # it_behaves_like 'contains_publisher_data' # No, it does not.
    it_behaves_like 'contains_summary_data'
  end
end
