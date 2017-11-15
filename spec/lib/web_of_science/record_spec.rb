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
        expect(wos_record_encoded).to be_an described_class
      end
      it 'works with WOS decoded records' do
        expect(wos_record_decoded).to be_an described_class
      end
    end
    context 'MEDLINE records' do
      it 'works with MEDLINE encoded records' do
        expect(medline_record_encoded).to be_an described_class
      end
      it 'works with MEDLINE decoded records' do
        expect(medline_record_decoded).to be_an described_class
      end
    end
    it 'raises RuntimeError with nil params' do
      expect { described_class.new }.to raise_error(RuntimeError)
    end
  end

  describe '#doc' do
    it 'works with encoded records' do
      result = wos_record_encoded.doc
      expect(result).to be_an Nokogiri::XML::Document
    end
    it 'works with decoded records' do
      result = wos_record_decoded.doc
      expect(result).to be_an Nokogiri::XML::Document
    end
  end

  # ---
  # Data accessors

  shared_examples 'it is an array of names' do
    it 'is an Array' do
      expect(agents).to be_an Array
    end
    it 'contains name data' do
      expect(agents.count).to eq 1
    end
    it 'contains first_name' do
      expect(agents.first).to include('first_name' => 'DC')
    end
    it 'contains last_name' do
      expect(agents.first).to include('last_name' => 'WEBER')
    end
    it 'contains role' do
      expect(agents.first).to include('role' => 'author')
    end
    it 'missing attribute data is nil' do
      expect(agents.first['reprint']).to be_nil
    end
  end

  describe '#authors' do
    let(:agents) { wos_record_encoded.authors }

    it_behaves_like 'it is an array of names'
  end

  describe '#names' do
    let(:agents) { wos_record_encoded.names }

    it_behaves_like 'it is an array of names'
  end

  describe '#identifiers' do
    it 'works' do
      result = wos_record_encoded.identifiers
      expect(result).to be_an WebOfScience::Identifiers
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
        'page'         => { 'end' => '413', 'page_count' => '1', 'begin' => '413' }
      }
    end

    it 'works' do
      expect(pub_info).to be_an Hash
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
      expect(publishers.first).to be_an Hash
    end
    it 'contains publisher name' do
      expect(publishers.first).to include('full_name' => 'ASSOC COLL RESEARCH LIBRARIES')
    end
  end

  describe '#summary' do
    let(:summary) { wos_record_encoded.summary }

    it 'works' do
      expect(summary).to be_an Hash
    end
    it 'contains doctypes Array' do
      expect(summary['doctypes']).to be_an Array
    end
    it 'contains names Array' do
      expect(summary['names']).to be_an Array
    end
    it 'contains pub_info Hash' do
      expect(summary['pub_info']).to be_an Hash
    end
    it 'contains publishers Array' do
      expect(summary['publishers']).to be_an Array
    end
    it 'contains titles Hash' do
      expect(summary['titles']).to be_an Hash
    end
  end

  describe '#summary_struct' do
    let(:summary) { wos_record_encoded.summary_struct }

    it 'works' do
      expect(summary).to be_an OpenStruct
    end
    it 'contains doctypes Array' do
      expect(summary.doctypes).to be_an Array
    end
    it 'contains names Array' do
      expect(summary.names).to be_an Array
    end
    it 'contains pub_info OpenStruct' do
      expect(summary.pub_info).to be_an OpenStruct
    end
    it 'contains publishers Array' do
      expect(summary.publishers).to be_an Array
    end
    it 'contains titles OpenStruct' do
      expect(summary.titles).to be_an OpenStruct
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
      expect(hash).to be_an Hash
    end
    it 'contains summary fields' do
      expect(hash['summary']).to eq wos_record_encoded.summary
    end
  end

  describe '#to_struct' do
    let(:struct) { wos_record_encoded.to_struct }

    it 'works' do
      expect(struct).to be_an OpenStruct
    end
    it 'contains summary fields' do
      expect(struct.summary).to be_an OpenStruct
    end
  end

  # ---
  # XML specs

  shared_examples 'it has well formed XML' do
    let(:html_char) { '&lt;' }

    it 'returns an XML String' do
      expect(xml_result).to be_an String
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
