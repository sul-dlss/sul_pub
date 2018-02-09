require 'htmlentities'

describe WebOfScience::Record do
  let(:wos_encoded_record) { File.read('spec/fixtures/wos_client/wos_encoded_record.html') }
  let(:wos_decoded_record) do
    coder = HTMLEntities.new
    coder.decode(wos_encoded_record)
  end
  let(:wos_record_encoded) { described_class.new(encoded_record: wos_encoded_record) }
  let(:wos_record_decoded) { described_class.new(record: wos_decoded_record) }
  let(:wos_uid) { 'WOS:A1972N549400003' }

  let(:medline_encoded_record) { File.read('spec/fixtures/wos_client/medline_encoded_record.html') }
  let(:medline_decoded_record) do
    coder = HTMLEntities.new
    coder.decode(medline_encoded_record)
  end
  let(:medline_record_encoded) { described_class.new(encoded_record: medline_encoded_record) }
  let(:medline_record_decoded) { described_class.new(record: medline_decoded_record) }
  let(:medline_uid) { 'MEDLINE:24452614' }

  describe '#new' do
    context 'WOS records' do
      it 'works with WOS encoded records' do
        expect(wos_record_encoded).to be_a described_class
      end
      it 'works with WOS decoded records' do
        expect(wos_record_decoded).to be_a described_class
      end
    end
    context 'MEDLINE records' do
      it 'works with MEDLINE encoded records' do
        expect(medline_record_encoded).to be_a described_class
      end
      it 'works with MEDLINE decoded records' do
        expect(medline_record_decoded).to be_a described_class
      end
    end
    it 'raises RuntimeError with nil params' do
      expect { described_class.new }.to raise_error(RuntimeError)
    end
  end

  describe '#doc' do
    it 'works with encoded records' do
      expect(wos_record_encoded.doc).to be_a Nokogiri::XML::Document
    end
    it 'works with decoded records' do
      expect(wos_record_decoded.doc).to be_a Nokogiri::XML::Document
    end
  end

  # ---
  # WebOfScienceSourceRecord utils

  context 'WebOfScienceSourceRecord does not exist' do
    it '#source_record returns nil' do
      expect(wos_record_decoded.source_record).to be_nil
    end
    it '#source_record_attr returns Hash' do
      expect(wos_record_decoded.source_record_attr).to be_a Hash
    end
    it '#source_record_find_or_create returns WebOfScienceSourceRecord' do
      expect(wos_record_decoded.source_record_find_or_create).to be_a WebOfScienceSourceRecord
    end
    it '#source_record_update returns false' do
      expect(wos_record_decoded.source_record_update).to be false
    end
  end

  context 'WebOfScienceSourceRecord exists' do
    let(:wos_src_record) { wos_record_decoded.source_record_find_or_create }

    before { expect(wos_src_record.uid).to be_a String }
    after { wos_src_record.destroy }

    it '#source_record returns nil' do
      expect(wos_record_decoded.source_record).to eq wos_src_record
    end
    it '#source_record_find_or_create returns WebOfScienceSourceRecord' do
      new_src_record = wos_record_decoded.source_record_find_or_create
      expect(new_src_record).to be_a WebOfScienceSourceRecord
      expect(new_src_record.id).to eq wos_record_decoded.source_record_find_or_create.id
    end
    it '#source_record_update returns nil when fingerprints match' do
      expect(wos_record_decoded.source_record_update).to be false
    end
    it '#source_record_update returns true when fingerprints differ' do
      attr = wos_record_decoded.source_record_attr
      attr[:source_data].gsub!('STANFORD UNIV', 'Stanford University')
      allow(wos_record_decoded).to receive(:source_record_attr).and_return(attr)
      expect { wos_record_decoded.source_record_update }.to change { wos_src_record.reload.source_fingerprint }
    end
  end

  # ---
  # Data accessors

  shared_examples 'it is an array of names' do
    it 'is an Array' do
      expect(agents).to be_an Array
    end
    it 'contains name data' do
      expect(agents).not_to be_empty
    end
    it 'conforms to expected key-value pairs' do
      expect(agent).to include('first_name' => String, 'last_name' => String, 'role' => String)
    end
    it 'missing attribute data is nil' do
      expect(agent).not_to include('reprint')
    end
  end

  describe '#authors' do
    let(:agents) { wos_record_encoded.authors }
    let(:agent) { agents.first }

    it_behaves_like 'it is an array of names'
    it 'contains author values' do
      expect(agent).to include('first_name' => 'DC', 'last_name' => 'WEBER', 'role' => 'author')
    end
  end

  describe '#editors' do
    let(:wos_xml) { File.read('spec/fixtures/wos_client/wos_record_000386326200035.xml') }
    let(:wos_record) { described_class.new(record: wos_xml) }
    let(:wos_uid) { 'WOS:000386326200035' }

    let(:agents) { wos_record.editors }
    let(:agent) { agents.first }

    it_behaves_like 'it is an array of names'
    it 'contains editor values' do
      expect(agent).to include('first_name' => 'TE', 'last_name' => 'Klein', 'role' => 'book_editor')
    end
  end

  describe '#names' do
    let(:agents) { wos_record_encoded.names }
    let(:agent) { agents.first }

    it_behaves_like 'it is an array of names'
  end

  describe '#identifiers' do
    it 'works' do
      result = wos_record_encoded.identifiers
      expect(result).to be_a WebOfScience::Identifiers
    end

    describe '#database' do
      # check that it is delegated successfully to identifiers
      it 'works' do
        expect(wos_record_encoded.database).to eq wos_uid.split(':').first
      end
    end

    describe '#uid' do
      # check that it is delegated successfully to identifiers
      it 'WOS records have a WOS-UID' do
        expect(wos_record_encoded.uid).to eq wos_uid
      end
      it 'MEDLINE records have a MEDLINE-UID (PMID)' do
        expect(medline_record_encoded.uid).to eq medline_uid
      end
    end
  end

  describe '#doctypes' do
    let(:doctypes) { wos_record_encoded.doctypes }

    it 'works' do
      expect(doctypes).to be_an Array
    end
    it 'includes a doctype' do
      expect(doctypes).to include 'Book Review'
    end
  end

  describe '#print' do
    it 'works' do
      expect { wos_record_encoded.print }.to output.to_stdout
    end
  end

  describe '#pub_info' do
    let(:pub_info) { wos_record_encoded.pub_info }
    let(:pub_info_hash) do
      { 'issue'        => '5',
        'pubtype'      => 'Journal',
        'sortdate'     => '1972-01-01',
        'has_abstract' => 'N',
        'coverdate'    => '1972',
        'vol'          => '33',
        'pubyear'      => '1972',
        'page'         => { 'end' => '413', 'page_count' => '1', 'begin' => '413' } }
    end

    it 'works' do
      expect(pub_info).to be_a Hash
    end
    it 'has issue' do
      expect(pub_info['issue']).to eq pub_info_hash['issue']
    end
    it 'has page' do
      expect(pub_info['page']).to eq pub_info_hash['page']
    end
    it 'has pubtype' do
      expect(pub_info['pubtype']).to eq pub_info_hash['pubtype']
    end
    it 'has pubyear' do
      expect(pub_info['pubyear']).to eq pub_info_hash['pubyear']
    end
    it 'has vol' do
      expect(pub_info['vol']).to eq pub_info_hash['vol']
    end
  end

  describe '#publishers' do
    let(:publishers) { wos_record_encoded.publishers }

    it 'works' do
      expect(publishers).to be_an Array
    end
    it 'contains publisher information' do
      expect(publishers.first).to be_a Hash
    end
    it 'contains publisher name' do
      expect(publishers.first).to include('full_name' => 'ASSOC COLL RESEARCH LIBRARIES')
    end
  end

  describe '#pub_hash' do
    let(:pub_hash) { wos_record_encoded.pub_hash }

    it 'works' do
      expect(pub_hash).to be_a Hash
    end
    it 'has "wos" provenance' do
      expect(pub_hash[:provenance]).to eq 'wos'
    end
  end

  describe '#titles' do
    it 'works' do
      result = wos_record_encoded.titles
      expect(result).to include('source' => 'COLLEGE & RESEARCH LIBRARIES')
    end
  end

  describe '#to_h' do
    let(:hash) { wos_record_encoded.to_h }

    it 'works' do
      expect(hash).to be_a Hash
    end
    it 'contains doctypes Array' do
      expect(hash['doctypes']).to be_an Array
    end
    it 'contains names Array' do
      expect(hash['names']).to be_an Array
    end
    it 'contains pub_info Hash' do
      expect(hash['pub_info']).to be_a Hash
    end
    it 'contains publishers Array' do
      expect(hash['publishers']).to be_an Array
    end
    it 'contains titles Hash' do
      expect(hash['titles']).to be_a Hash
    end
  end

  describe '#to_struct' do
    let(:struct) { wos_record_encoded.to_struct }

    it 'works' do
      expect(struct).to be_an OpenStruct
    end
    it 'contains doctypes Array' do
      expect(struct.doctypes).to be_an Array
    end
    it 'contains names Array' do
      expect(struct.names).to be_an Array
    end
    it 'contains pub_info OpenStruct' do
      expect(struct.pub_info).to be_an OpenStruct
    end
    it 'contains publishers Array' do
      expect(struct.publishers).to be_an Array
    end
    it 'contains titles OpenStruct' do
      expect(struct.titles).to be_an OpenStruct
    end
  end

  # ---
  # XML specs

  shared_examples 'it has well formed XML' do
    let(:html_char) { '&lt;' }

    it 'returns an XML String' do
      expect(xml_result).to be_a String
    end
    it 'returns well formed XML' do
      expect do
        Nokogiri::XML(xml_result) { |config| config.strict.noblanks }
      end.not_to raise_error
    end
    it 'contains no HTML encoding' do
      expect(xml_result).not_to include html_char
    end
  end

  describe '#to_xml' do
    let(:xml_result) { wos_record_encoded.to_xml }

    it_behaves_like 'it has well formed XML'
  end
end
