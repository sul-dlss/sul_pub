describe WebOfScience::MapMesh do
  subject(:mapper) { described_class.new(record) }

  let(:medline_xml) { File.read('spec/fixtures/wos_client/medline_record_26776186.xml') }
  let(:record) { WebOfScience::Record.new(record: medline_xml) }
  let(:pub_hash) { mapper.pub_hash }

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

  shared_examples 'medline_works' do
    it 'works with MEDLINE records' do
      expect(mapper).to be_an described_class
    end
  end

  shared_examples 'pub_hash' do
    it 'works' do
      expect(pub_hash).to be_an Hash
    end
  end

  shared_examples 'no_mesh' do
    it 'works' do
      expect(mapper.mesh).to be_empty
    end
    it 'pub_hash has no MESH headings' do
      expect(pub_hash[:mesh_headings]).to be_nil
    end
  end

  context 'MEDLINE record with MESH headings' do
    # use the default subject/record in this context
    let(:mesh_heading) { pub_hash[:mesh_headings].first }
    let(:descriptors) { mesh_heading[:descriptor] }
    let(:qualifiers) { mesh_heading[:qualifier] }
    let(:tree_codes) { mesh_heading[:treecode] }

    it_behaves_like 'medline_works'
    it_behaves_like 'pub_hash'

    it 'works' do
      expect(mapper.mesh).not_to be_empty
    end
    it 'pub_hash has MESH headings' do
      expect(pub_hash[:mesh_headings]).to be_an Array
    end
    it 'a MESH heading has descriptor' do
      expect(descriptors).to be_an Array
    end
    it 'a MESH descriptor has key:value pattern' do
      expect(descriptors.first).to include(name: 'Computational Biology', major: 'N', id: 'D019295')
    end
    it 'a MESH heading has qualifier' do
      expect(qualifiers).to be_an Array
    end
    it 'a MESH qualifier has key:value pattern' do
      expect(qualifiers.first).to include(name: 'methods', major: 'N', id: 'Q000379')
    end
    it 'a MESH heading has tree codes' do
      expect(tree_codes).to be_an Array
    end
    it 'a MESH tree code has key:value pattern' do
      expect(tree_codes.first).to include(code: 'H01.158.273.180', major: 'N')
    end
  end

  context 'MEDLINE record without MESH headings' do
    let(:medline_xml) { File.read('spec/fixtures/wos_client/medline_record_24452614.xml') }
    let(:record) { WebOfScience::Record.new(record: medline_xml) }

    it_behaves_like 'medline_works'
    it_behaves_like 'pub_hash'
    it_behaves_like 'no_mesh'
  end

  # Note: cannot find any WOS-db records with MESH headings (as expected)
  # Note: WOS-db records have relate content that is not extracted here:
  # /REC/static_data/fullrecord_metadata/category_info/headings/heading
  # /REC/static_data/fullrecord_metadata/category_info/subjects/subject
  context 'WOS record without MESH headings' do
    let(:wos_xml) { File.read('spec/fixtures/wos_client/wos_record_000268565100019.xml') }
    let(:record) { WebOfScience::Record.new(record: wos_xml) }

    it 'works with WOS records' do
      expect(mapper).to be_an described_class
    end
    it_behaves_like 'pub_hash'
    it_behaves_like 'no_mesh'
  end
end
