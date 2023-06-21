# frozen_string_literal: true

RSpec.describe WebOfScienceSourceRecord do
  subject(:wos_src_rec) { build(:web_of_science_source_record) }

  let(:records) { WebOfScience::Records.new(records: "<records>#{record_xml}</records>") }
  let(:record_xml) { File.read('spec/fixtures/wos_client/wos_record_000288663100014.xml') }

  context 'initialize a new record' do
    it 'can be created without a WOS source record but is invalid' do
      expect { described_class.new }.not_to raise_error
      expect(described_class.new).not_to be_valid
    end

    it 'extracts attributes from source_data' do
      expect(wos_src_rec).to be_valid # trigger extractions
      expect(wos_src_rec.uid).to eq 'WOS:A1972N549400003'
      expect(wos_src_rec.database).to eq 'WOS'
      expect(wos_src_rec.source_fingerprint).to eq 'e5088910f3e61f73eebaa4c8938c742989259f3821f2a050de57475e7f385445'
      expect(wos_src_rec).to be_active
    end

    it 'extracts attributes from WebOfScience::Record' do
      other = described_class.new(record: records.first)
      expect(other).to be_valid # trigger extractions
      expect(other.uid).to eq 'WOS:000288663100014'
      expect(other.database).to eq 'WOS'
      expect(other.source_data).not_to be_empty
      expect(other.source_fingerprint).to eq '8f801264c356bc7005013e270568e87365591e8c3286e74f5bb865aec4cedd8a'
    end
  end

  context 'sets identifiers' do
    before do
      identifiers = WebOfScience::Identifiers.new(build(:web_of_science_source_record).record)
      allow(identifiers).to receive(:doi).and_return('doi')
      allow(identifiers).to receive(:pmid).and_return('123')
      allow(WebOfScience::Identifiers).to receive(:new).and_return(identifiers)
      wos_src_rec.save!
    end

    it 'sets attributes' do
      expect(wos_src_rec.doi).to eq 'doi'
      expect(wos_src_rec.pmid).to eq 123
    end

    it 'allows select' do
      expect(described_class.select(:id).first).to be_a described_class
    end
  end

  context 'source record validation' do
    it 'works' do
      expect(wos_src_rec).to be_valid
      expect { wos_src_rec.save! }.not_to raise_error
    end

    describe 'unique constraints' do
      let(:dup) { wos_src_rec.dup }

      before { wos_src_rec.save! }

      it 'prevents duplicate uid' do
        dup.source_fingerprint = '123'
        expect { dup.save! }.to raise_error(ActiveRecord::RecordNotUnique)
      end

      it 'prevents duplicate source_fingerprint' do
        dup.uid = '123'
        expect { dup.save! }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe '#publication' do
    let(:pub) { create(:publication, wos_uid: 'WOS:A1972N549400003') }

    it 'assignment works' do
      wos_src_rec.publication = pub
      expect { wos_src_rec.save! }.not_to raise_error
      expect(wos_src_rec.publication).to eq pub
      expect(wos_src_rec.publication.wos_uid).to eq wos_src_rec.uid
    end
  end

  context 'utility methods' do
    it 'has a Nokogiri::XML::Document' do
      expect(wos_src_rec.doc).to be_a Nokogiri::XML::Document
    end

    it 'has a WebOfScience::Record' do
      expect(wos_src_rec.record).to be_a WebOfScience::Record
    end

    it 'has an XML String' do
      expect(wos_src_rec.to_xml).to be_a String
    end

    it 'an XML String from the doc utility matches the source_data' do
      # TODO: use equivalent_xml
      expect(wos_src_rec.to_xml).to eq wos_src_rec.source_data
    end
  end
end
