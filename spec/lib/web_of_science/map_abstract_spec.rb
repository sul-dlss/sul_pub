describe WebOfScience::MapAbstract do
  subject(:mapper) { described_class.new(wos_record) }

  let(:wos_encoded_xml) { File.read('spec/fixtures/wos_client/wos_encoded_record.html') }
  let(:wos_record) { WebOfScience::Record.new(encoded_record: wos_encoded_xml) }

  let(:medline_encoded_xml) { File.read('spec/fixtures/wos_client/medline_encoded_record.html') }
  let(:medline_record) { WebOfScience::Record.new(encoded_record: medline_encoded_xml) }

  describe '#new' do
    it 'works with WOS records' do
      expect(mapper).to be_an described_class
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
  end

  shared_examples 'abstracts' do
    it 'works' do
      expect(mapper.abstracts).not_to be_empty
    end
  end

  shared_examples 'no_abstracts' do
    it 'works' do
      expect(mapper.abstracts).to be_empty
    end
  end

  shared_examples 'abstract' do
    it 'pub_hash has an abstract_restricted' do
      expect(pub_hash[:abstract]).not_to be_nil
    end
  end

  shared_examples 'no_abstract' do
    it 'pub_hash has no abstract_restricted' do
      expect(pub_hash[:abstract]).to be_nil
    end
  end

  shared_examples 'abstract_restricted' do
    it 'pub_hash has an abstract_restricted' do
      expect(pub_hash[:abstract_restricted]).not_to be_nil
    end
  end

  shared_examples 'no_abstract_restricted' do
    it 'pub_hash has no abstract_restricted' do
      expect(pub_hash[:abstract_restricted]).to be_nil
    end
  end

  context 'WOS record with no abstract' do
    subject(:mapper) { described_class.new(wos_record) }

    let(:pub_hash) { mapper.pub_hash }

    it 'works with WOS records' do
      expect(mapper).to be_an described_class
    end
    it_behaves_like 'pub_hash'
    it_behaves_like 'no_abstracts'
    it_behaves_like 'no_abstract'
    it_behaves_like 'no_abstract_restricted'
  end

  context 'WOS record with an abstract' do
    subject(:mapper) { described_class.new(wos_record) }

    let(:wos_xml) { File.read('spec/fixtures/wos_client/wos_record_000268565100019.xml') }
    let(:wos_record) { WebOfScience::Record.new(record: wos_xml) }
    let(:pub_hash) { mapper.pub_hash }

    it 'works with WOS records' do
      expect(mapper).to be_an described_class
    end
    it_behaves_like 'pub_hash'
    it_behaves_like 'abstracts'
    it_behaves_like 'no_abstract'
    it_behaves_like 'abstract_restricted'
  end

  context 'MEDLINE records' do
    subject(:mapper) { described_class.new(medline_record) }

    let(:pub_hash) { mapper.pub_hash }

    it 'works with MEDLINE records' do
      expect(mapper).to be_an described_class
    end
    it_behaves_like 'pub_hash'
    it_behaves_like 'abstracts'
    it_behaves_like 'abstract'
    it_behaves_like 'no_abstract_restricted'
  end
end
