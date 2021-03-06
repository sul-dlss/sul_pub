# frozen_string_literal: true

require 'htmlentities'

describe WebOfScience::Records do
  let(:wos_encoded_records) { File.read('spec/fixtures/wos_client/wos_encoded_records.html') }
  let(:wos_records_encoded) { described_class.new(encoded_records: wos_encoded_records) }
  let(:wos_records_decoded) { described_class.new(records: HTMLEntities.new.decode(wos_encoded_records)) }

  let(:medline_uids) { %w[MEDLINE:21121048 MEDLINE:7584390 MEDLINE:26776202 MEDLINE:24452614 MEDLINE:24303232] }
  let(:medline_encoded_records) { File.read('spec/fixtures/wos_client/medline_encoded_records.html') }
  let(:medline_records_encoded) { described_class.new(encoded_records: medline_encoded_records) }

  let(:recordsA) do
    <<-XML_A
        <records>
          <REC><UID>WOS:A1</UID></REC>
          <REC><UID>WOS:A2</UID></REC>
        </records>
    XML_A
  end
  let(:recordsB) do
    <<-XML_B
        <records>
          <REC><UID>WOS:A2</UID></REC>
          <REC><UID>WOS:B2</UID></REC>
        </records>
    XML_B
  end
  let(:wos_recordsA) { described_class.new(records: recordsA) }
  let(:wos_recordsB) { described_class.new(records: recordsB) }

  describe '#new' do
    context 'WOS records' do
      it 'works with encoded records' do
        expect(wos_records_encoded).to be_an described_class
      end

      it 'works with decoded records' do
        expect(wos_records_decoded).to be_an described_class
      end
    end

    context 'MEDLINE records' do
      it 'works with encoded records' do
        expect(medline_records_encoded).to be_an described_class
      end
    end
  end

  describe '#count' do
    it 'returns Integer' do
      expect(wos_records_encoded.count).to be_an Integer
    end

    it 'delegates to rec_nodes.count' do
      expect(wos_records_encoded.count).to eq wos_records_encoded.rec_nodes.count
    end
  end

  describe '#doc' do
    it 'works with encoded records' do
      expect(wos_records_encoded.doc).to be_a Nokogiri::XML::Document
    end

    it 'works with decoded records' do
      expect(wos_records_decoded.doc).to be_a Nokogiri::XML::Document
    end
  end

  describe '#each' do
    it 'yields WebOfScience::Record objects' do
      wos_records_encoded.all? { |rec| expect(rec).to be_an WebOfScience::Record }
    end
  end

  describe '#empty?' do
    it 'delegates to rec_nodes.empty?' do
      expect(wos_records_encoded.empty?).to eq wos_records_encoded.rec_nodes.empty?
    end

    it 'returns false when records exist' do
      expect(wos_records_encoded.empty?).to be false
    end

    it 'returns true when records are missing' do
      wos_records = described_class.new(records: '<records/>')
      expect(wos_records.empty?).to be true
    end
  end

  describe 'Enumerable mixin' do
    it 'is_a? Enumerable' do
      expect(wos_records_decoded).to be_an Enumerable
    end
  end

  describe '#uids' do
    it 'works with encoded records' do
      result = wos_records_encoded.uids
      expect(result).to be_an Array
      expect(result.first).to be_an String
    end

    it 'works with decoded records' do
      result = wos_records_decoded.uids
      expect(result).to be_an Array
      expect(result.first).to be_an String
    end

    context 'MEDLINE records' do
      it 'works with encoded records' do
        expect(medline_records_encoded.uids).to include medline_uids.sample
      end
    end
  end

  describe '#duplicate_uids' do
    let(:dup_uids) { wos_recordsA.duplicate_uids(wos_recordsB) }

    it 'works' do
      expect(dup_uids).to be_an Array
    end

    it 'returns duplicate UIDs' do
      expect(dup_uids.to_a).to eq ['WOS:A2']
    end

    it 'does not modify records' do
      expect { dup_uids }.not_to change(wos_recordsA, :uids)
    end

    it 'does not modify input records' do
      expect { dup_uids }.not_to change(wos_recordsB, :uids)
    end
  end

  describe '#duplicate_records' do
    let(:dup_records) { wos_recordsA.duplicate_records(wos_recordsB) }

    it 'works' do
      expect(dup_records).to be_an Nokogiri::XML::NodeSet
    end

    it 'returns duplicate record nodes' do
      uid = dup_records.search('UID').text
      expect(uid).to eq 'WOS:A2'
    end

    it 'does not modify records' do
      expect { dup_records }.not_to change(wos_recordsA, :uids)
    end

    it 'does not modify input records' do
      expect { dup_records }.not_to change(wos_recordsB, :uids)
    end
  end

  describe '#new_records' do
    let(:new_records) { wos_recordsA.new_records(wos_recordsB) }

    it 'works' do
      expect(new_records).to be_an Nokogiri::XML::NodeSet
    end

    it 'returns new record nodes' do
      expect(new_records.search('UID').text).to eq 'WOS:B2'
    end

    it 'does not modify records' do
      expect { new_records }.not_to change(wos_recordsA, :uids)
    end

    it 'does not modify input records' do
      expect { new_records }.not_to change(wos_recordsB, :uids)
    end
  end

  describe '#merge_records' do
    let(:merge_records) { wos_recordsA.merge_records(wos_recordsB) }

    it 'works' do
      expect(merge_records).to be_an described_class
    end

    it 'has merged records' do
      expect(merge_records.uids).to eq %w[WOS:A1 WOS:A2 WOS:B2]
    end
    # Immutability specs

    it 'does not modify records' do
      expect { merge_records }.not_to change(wos_recordsA, :uids)
    end

    it 'does not modify input records' do
      expect { merge_records }.not_to change(wos_recordsB, :uids)
    end
  end

  describe '#print' do
    it 'works with encoded records' do
      expect { wos_records_encoded.print }.to output.to_stdout
    end

    it 'works with decoded records' do
      expect { wos_records_decoded.print }.to output.to_stdout
    end
  end

  describe '#rec_nodes' do
    let(:rec_nodes) { wos_records_decoded.rec_nodes }

    it 'works' do
      expect(rec_nodes).not_to be_nil
    end
  end

  describe '#records_by_database' do
    let(:records_by_db) do
      <<-XML_DBS
        <records>
          <REC><UID>WOS:012</UID></REC>
          <REC><UID>WOS:123</UID></REC>
          <REC><UID>MEDLINE:234</UID></REC>
          <REC><UID>MEDLINE:345</UID></REC>
          <!-- no db identifier -->
          <REC><UID>456</UID></REC>
          <REC><UID>567</UID></REC>
        </records>
      XML_DBS
    end
    let(:db_records) { described_class.new(records: records_by_db) }
    let(:nodes_wos) { db_records.by_database['WOS'] }
    let(:nodes_medline) { db_records.by_database['MEDLINE'] }
    let(:nodes_missing_db) { db_records.by_database['MISSING_DB'] }
    let(:nodes_none) { db_records.by_database['BIO-XX'] }

    it 'returns a Hash<String => WebOfScience::Records>' do
      by_db = db_records.by_database
      expect(by_db).to be_an Hash
      expect(by_db.keys.first).to be_an String
      expect(by_db['WOS']).to be_an described_class
    end

    it 'extracts WOS records' do
      expect(nodes_wos.count).to eq 2
    end

    it 'extracts MEDLINE records' do
      expect(nodes_medline.count).to eq 2
    end

    it 'returns MISSING_DB for records without a database prefix in the UID' do
      expect(nodes_missing_db.count).to eq 2
    end

    it 'returns nil when no matching database exists' do
      expect(nodes_none).to be_nil
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
    context 'with encoded records' do
      let(:xml_result) { wos_records_encoded.to_xml }

      it_behaves_like 'it has well formed XML'
    end

    context 'with decoded records' do
      let(:xml_result) { wos_records_decoded.to_xml }

      it_behaves_like 'it has well formed XML'
    end
  end
end
