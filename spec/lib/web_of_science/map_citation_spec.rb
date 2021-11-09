# frozen_string_literal: true

describe WebOfScience::MapCitation do
  let(:wos_encoded_xml) { File.read('spec/fixtures/wos_client/wos_encoded_record.html') }
  let(:wos_record) { WebOfScience::Record.new(encoded_record: wos_encoded_xml) }

  let(:medline_encoded_xml) { File.read('spec/fixtures/wos_client/medline_encoded_record.html') }
  let(:medline_record) { WebOfScience::Record.new(encoded_record: medline_encoded_xml) }

  let(:mapper) { described_class.new(wos_record) } # default
  let(:pub_hash) { mapper.pub_hash }

  describe '#new' do
    it 'works with WOS records' do
      expect { described_class.new(wos_record) }.not_to raise_error
    end

    it 'works with MEDLINE records' do
      expect { described_class.new(medline_record) }.not_to raise_error
    end

    it 'raises ArgumentError with bad params' do
      expect { described_class.new }.to raise_error(ArgumentError)
      expect { described_class.new('could be xml') }.to raise_error(ArgumentError)
    end
  end

  shared_examples 'common_citation_data' do
    it 'extracts relevant fields' do
      expect(pub_hash).to match a_hash_including(
        year: String,
        date: String,
        title: String,
        journal: a_hash_including(:name, :identifier)
      )
      expect(pub_hash[:journal][:identifier]).to include(a_hash_including(type: 'issn', id: String))
    end
  end

  context 'WOS records' do
    it_behaves_like 'common_citation_data'
    it 'trims the whitespace from the title and maps the numeric page number' do
      # whitespace trimmed
      expect(pub_hash[:title]).to eq 'LIBRARY MANAGEMENT - BEHAVIOR-BASED PERSONNEL SYSTEMS (BBPS) - FRAMEWORK FOR ANALYSIS - KEMPER,RE'
      expect(pub_hash[:pages]).to eq '413'
    end
  end

  context 'MEDLINE records' do
    let(:mapper) { described_class.new(medline_record) }

    it_behaves_like 'common_citation_data'
    it 'trims the whitespace from the title and ignores the non-numeric page number' do
      # whitespace trimmed
      expect(pub_hash[:title]).to eq 'Identifying druggable targets by protein microenvironments matching: application to transcription factors.'
      expect(pub_hash[:pages]).to be nil # this record has a non numeric page number of "e93", which will be ignored
    end
  end
end
