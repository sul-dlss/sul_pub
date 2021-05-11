# frozen_string_literal: true

describe WebOfScience::MapPubHash do
  let(:wos_encoded_xml) { File.read('spec/fixtures/wos_client/wos_encoded_record.html') }
  let(:wos_record) { WebOfScience::Record.new(encoded_record: wos_encoded_xml) }

  let(:medline_xml) { File.read('spec/fixtures/wos_client/medline_record_26776186.xml') }
  let(:medline_record) { WebOfScience::Record.new(record: medline_xml) }

  let(:mapper) { described_class.new(record) }
  let(:pub_hash) { mapper.pub_hash }
  let(:record) { wos_record } # default

  describe '#new' do
    it 'works with WOS records' do
      expect { described_class.new(wos_record) }.not_to raise_error
    end
    it 'raises ArgumentError with bad params' do
      expect { described_class.new }.to raise_error(ArgumentError)
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
    it_behaves_like 'pub_hash'
    it_behaves_like 'common_citation_data'
    it_behaves_like 'contains_publisher_data'
    it_behaves_like 'contains_summary_data'
  end

  context 'MEDLINE records' do
    let(:record) { medline_record }

    it_behaves_like 'pub_hash'
    it_behaves_like 'common_citation_data'
    # it_behaves_like 'contains_publisher_data' # No, it does not.
    it_behaves_like 'contains_summary_data'
    it 'contains MESH headings' do
      expect(pub_hash[:mesh_headings]).to be_an Array
    end
  end

  # private

  describe '#pub_hash_doctypes' do
    let(:doctypes) { mapper.send(:pub_hash_doctypes, record) }

    it 'parses out salient fields' do
      expect(doctypes).to match a_hash_including(
        documenttypes_sw: ['Book Review', 'Journal'],
        documentcategory_sw: 'Journal',
        type: 'article'
      )
    end
    it 'detects conference doctypes' do
      allow(record).to receive(:doctypes).and_return ['Meeting Abstract']
      expect(doctypes).to match a_hash_including(type: 'inproceedings')
    end
  end
end
