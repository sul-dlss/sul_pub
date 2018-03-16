require 'htmlentities'

describe WebOfScience::Record do
  let(:encoded_html) { File.read('spec/fixtures/wos_client/wos_encoded_record.html') }
  let(:wos_record_encoded) { described_class.new(encoded_record: encoded_html) }
  let(:wos_record_decoded) { described_class.new(record: HTMLEntities.new.decode(encoded_html)) }
  let(:uid) { 'WOS:A1972N549400003' }

  let(:medline_html) { File.read('spec/fixtures/wos_client/medline_encoded_record.html') }
  let(:medline_record_encoded) { described_class.new(encoded_record: medline_html) }
  let(:medline_record_decoded) { described_class.new(record: HTMLEntities.new.decode(medline_html)) }

  describe '#new' do
    context 'WOS records' do
      it 'works with encoded and decoded records' do
        expect(wos_record_encoded).to be_an described_class
        expect(wos_record_decoded).to be_an described_class
      end
    end
    context 'MEDLINE records' do
      it 'works with encoded and decoded records' do
        expect(medline_record_encoded).to be_an described_class
        expect(medline_record_decoded).to be_an described_class
      end
    end
    it 'raises RuntimeError with nil params' do
      expect { described_class.new }.to raise_error(RuntimeError)
    end
  end

  describe '#doc' do
    it 'works with encoded and decoded records' do
      expect(wos_record_encoded.doc).to be_an Nokogiri::XML::Document
      expect(wos_record_decoded.doc).to be_an Nokogiri::XML::Document
    end
  end

  # Data accessors

  shared_examples 'it is an array of names' do
    it 'is an populated Array' do
      expect(agents).to be_an Array
      expect(agents).not_to be_empty
    end
    it 'conforms to expected key-value pairs' do
      expect(agent).to include('first_name' => String, 'last_name' => String, 'role' => String)
      expect(agent).not_to include('reprint')
    end
  end

  context 'names' do
    # In this WOS-record, Russ Altman is both an "author" and a "book_editor"
    let(:wos_record) { described_class.new(record: File.read('spec/fixtures/wos_client/wos_record_000386326200035.xml')) }
    let(:uid) { 'WOS:000386326200035' }
    let(:agent) { agents.first }

    describe '#authors' do
      let(:agents) { wos_record.authors }

      it_behaves_like 'it is an array of names'
      it 'contains author values' do
        expect(agent).to include('first_name' => 'Yong Fuga', 'last_name' => 'Li', 'role' => 'author')
      end
    end

    describe '#editors' do
      let(:agents) { wos_record.editors }
      it_behaves_like 'it is an array of names'
      it 'contains editor values' do
        expect(agent).to include('first_name' => 'RB', 'last_name' => 'Altman', 'role' => 'book_editor')
      end
    end

    describe '#names' do
      let(:agents) { wos_record.names }
      it_behaves_like 'it is an array of names'
    end
  end

  # check that it is delegated successfully to identifiers
  it '#database works' do
    expect(wos_record_encoded.database).to eq uid.split(':').first
  end
  it '#identifiers works' do
    expect(wos_record_encoded.identifiers).to be_an WebOfScience::Identifiers
  end

  describe '#uid' do
    # check that it is delegated successfully to identifiers
    it 'WOS records have a WOS-UID' do
      expect(wos_record_encoded.uid).to eq uid
    end
    it 'MEDLINE records have a MEDLINE-UID (PMID)' do
      expect(medline_record_encoded.uid).to eq 'MEDLINE:24452614'
    end
  end

  it '#doctypes works' do
    expect(wos_record_encoded.doctypes).to include('Book Review')
  end
  it '#print works' do
    expect { wos_record_encoded.print }.to output.to_stdout
  end

  describe '#pub_info' do
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
      expect(wos_record_encoded.pub_info).to match a_hash_including(pub_info_hash)
    end
  end

  it '#publishers works' do
    expect(wos_record_encoded.publishers).to include(a_hash_including('full_name' => 'ASSOC COLL RESEARCH LIBRARIES'))
  end
  it '#pub_hash works' do
    expect(wos_record_encoded.pub_hash).to match a_hash_including(provenance: 'wos')
  end
  it '#titles works' do
    expect(wos_record_encoded.titles).to include('source' => 'COLLEGE & RESEARCH LIBRARIES')
  end
  it '#to_h works' do
    expect(wos_record_encoded.to_h).to match a_hash_including(
      'doctypes'   => Array,
      'names'      => Array,
      'pub_info'   => Hash,
      'publishers' => Array,
      'titles'     => Hash
    )
  end

  # XML specs
  describe '#to_xml' do
    let(:xml_result) { wos_record_encoded.to_xml }
    let(:html_char) { '&lt;' }

    it 'returns an XML String' do
      expect(xml_result).to be_a String
    end
    it 'parses' do
      expect { Nokogiri::XML(xml_result) { |config| config.strict.noblanks } }.not_to raise_error
    end
    it 'contains no HTML encoding' do
      expect(xml_result).not_to include html_char
    end
  end

  describe '#find_or_create_model' do
    it 'persists WebOfScienceSourceRecord as needed' do
      expect(WebOfScienceSourceRecord.find_by(uid: wos_record_encoded.uid)).to be_nil
      wssr = wos_record_encoded.find_or_create_model
      expect(wssr).to be_a(WebOfScienceSourceRecord)
      expect(wssr.uid).to eq(wos_record_encoded.uid)
      expect(WebOfScienceSourceRecord.find_by(uid: wos_record_encoded.uid)).to eq(wssr)
    end
  end
end
