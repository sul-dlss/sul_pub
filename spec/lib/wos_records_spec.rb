require 'htmlentities'

describe WosRecords do
  let(:encoded_records) { File.read('spec/fixtures/wos_client/wos_encoded_records.html') }
  let(:decoded_records) do
    coder = HTMLEntities.new
    coder.decode(encoded_records)
  end
  let(:wos_records_encoded) { described_class.new(encoded_records: encoded_records) }
  let(:wos_records_decoded) { described_class.new(records: decoded_records) }

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
    it 'works with encoded records' do
      result = described_class.new(encoded_records: encoded_records)
      expect(result).to be_an described_class
    end
    it 'works with decoded records' do
      result = described_class.new(records: decoded_records)
      expect(result).to be_an described_class
    end
  end

  describe '#count' do
    it 'returns Integer' do
      count = wos_records_encoded.count
      expect(count).to be_an Integer
    end
    it 'delegates to rec_nodes.count' do
      count = wos_records_encoded.count
      expect(count).to eq wos_records_encoded.rec_nodes.count
    end
  end

  describe '#doc' do
    it 'works with encoded records' do
      result = wos_records_encoded.doc
      expect(result).to be_an Nokogiri::XML::Document
    end
    it 'works with decoded records' do
      result = wos_records_decoded.doc
      expect(result).to be_an Nokogiri::XML::Document
    end
  end

  describe '#each' do
    it 'yields WoS record elements' do
      wos_records_encoded.all? { |rec| expect(rec).to be_an Nokogiri::XML::Element }
    end
  end

  describe 'Enumerable mixin' do
    it 'responds to Enumerable.instance_methods' do
      methods = Enumerable.instance_methods
      methods.each { |method| expect(wos_records_encoded).to respond_to(method) }
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
      expect { dup_uids }.not_to change { wos_recordsA.uids }
    end
    it 'does not modify input records' do
      expect { dup_uids }.not_to change { wos_recordsB.uids }
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
      expect { dup_records }.not_to change { wos_recordsA.uids }
    end
    it 'does not modify input records' do
      expect { dup_records }.not_to change { wos_recordsB.uids }
    end
  end

  describe '#new_records' do
    let(:new_records) { wos_recordsA.new_records(wos_recordsB) }

    it 'works' do
      expect(new_records).to be_an Nokogiri::XML::NodeSet
    end
    it 'returns new record nodes' do
      uid = new_records.search('UID').text
      expect(uid).to eq 'WOS:B2'
    end
    it 'does not modify records' do
      expect { new_records }.not_to change { wos_recordsA.uids }
    end
    it 'does not modify input records' do
      expect { new_records }.not_to change { wos_recordsB.uids }
    end
  end

  describe '#merge_records' do
    let(:merge_records) { wos_recordsA.merge_records(wos_recordsB) }

    it 'works' do
      expect(merge_records).to be_an described_class
    end
    it 'has merged records' do
      expect(merge_records.uids).to eq %w(WOS:A1 WOS:A2 WOS:B2)
    end
    # Immutability specs
    it 'does not modify records' do
      expect { merge_records }.not_to change { wos_recordsA.uids }
    end
    it 'does not modify input records' do
      expect { merge_records }.not_to change { wos_recordsB.uids }
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

  # ---
  # XML specs

  shared_examples 'it has well formed XML' do
    let(:html_char) { '&lt;' }

    it 'returns an XML String' do
      expect(xml_result).to be_an String
    end
    it 'returns well formed XML' do
      expect do
        Nokogiri::XML(xml_result) { |config| config.strict }
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

  describe '#decode_records' do
    let(:xml_result) { wos_records_encoded.send(:decode_records) }

    it_behaves_like 'it has well formed XML'
  end
end
