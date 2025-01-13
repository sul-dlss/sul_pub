# frozen_string_literal: true

# NOTES
#
# Only WOS records can be supplemented by PubMed data.
# The spec example publications must have a valid PMID
# - for MEDLINE records, they have a PMID
# - for WOS records, they may not have PMID, but they could get one from the links service
#
# MESH headings - integration specs
# Note: not all PubMed/MEDLINE records contain MESH headings, so the
# spec example records were chosen to contain or fetch MESH headings

describe WebOfScience::ProcessPubmed, :vcr do
  subject(:processor) { test_class.new }

  let(:test_class) { Class.new { include WebOfScience::ProcessPubmed } }

  # Create a PubmedSourceRecord so it doesn't have to be fetched
  let(:wos_pmid) { '21253920' }
  let(:wos_pubmed_xml) { File.read('spec/fixtures/pubmed/pubmed_record_21253920.xml') }
  let(:wos_pubmed_rec) do
    wos_pubmed_doc = Nokogiri::XML(wos_pubmed_xml)
    PubmedSourceRecord.create_pubmed_source_record(wos_pmid, wos_pubmed_doc)
  end

  # NOTE: "WOS:000288663100014" has a PMID and it gets MESH headings from PubMed
  let(:wos_record_xml) { File.read('spec/fixtures/wos_client/wos_record_000288663100014.xml') }
  let(:wos_record_links) { { 'pmid' => '21253920', 'doi' => '10.1007/s12630-011-9462-1' } }
  let(:wos_record) do
    rec = WebOfScience::Record.new(record: wos_record_xml)
    rec.identifiers.update(wos_record_links)
    rec
  end
  let(:wos_pub) do
    wos_pub = Publication.new(active: true, pub_hash: wos_record.pub_hash, wos_uid: wos_record.uid)
    wos_pub.pubhash_needs_update!
    wos_pub.save!
    wos_pub
  end

  # Default spec data uses a MEDLINE record
  # Note: "MEDLINE:26776186" has a PMID and MESH headings
  let(:medline_pmid) { '26776186' }
  let(:medline_xml) { File.read('spec/fixtures/wos_client/medline_record_26776186.xml') }
  let(:record) { WebOfScience::Record.new(record: medline_xml) }
  let(:records) { [record] }
  let(:pub) do
    pub = Publication.new(active: true, pub_hash: record.pub_hash, wos_uid: record.uid)
    pub.pubhash_needs_update!
    pub.save!
    pub
  end

  before { allow(WebOfScience).to receive(:logger).and_return(Logger.new(File::NULL)) }

  describe '#pubmed_additions' do
    it 'catches and logs ArgumentError for records' do
      expect(NotificationManager).to receive(:error)
      expect { processor.pubmed_additions(['not wos-record']) }.not_to raise_error
    end

    it 'logs an error when a record publication cannot be found' do
      expect(Publication).to receive(:where).with(wos_uid: include(record.uid)).and_return(nil)
      expect(NotificationManager).to receive(:error)
      processor.pubmed_additions(records)
    end

    it 'adds the Publication.pmid, if possible' do
      expect { processor.pubmed_additions(records) }.to change { pub.reload.pmid }
    end

    it 'does not try #pubmed_addition for any MEDLINE records' do
      # the default records contains only a MEDLINE record
      expect(processor).not_to receive(:pubmed_addition).with(pub, record.pmid)
      processor.pubmed_additions(records)
    end

    it 'does try #pubmed_addition for any WOS records' do
      expect(wos_pub.wos_uid).to eq(wos_record.uid) # ensure a wos_pub record exists
      expect(wos_pubmed_rec.pmid).to eq(wos_record.pmid.to_i) # ensure a wos_pubmed record exists
      expect(PubmedSourceRecord).to receive(:for_pmid).with(wos_record.pmid).and_return(wos_pubmed_rec)
      processor.pubmed_additions([wos_record])
    end

    it 'does not try #pubmed_addition for any WOS records if pubmed lookups are disabled' do
      allow(Settings.PUBMED).to receive(:lookup_enabled).and_return(false)
      expect(wos_pub.wos_uid).to eq(wos_record.uid) # ensure a wos_pub record exists
      expect(wos_pubmed_rec.pmid).to eq(wos_record.pmid.to_i) # ensure a wos_pubmed record exists
      expect(PubmedSourceRecord).not_to receive(:for_pmid).with(wos_record.pmid)
      processor.pubmed_additions([wos_record])
    end
  end

  describe '#pubmed_addition' do
    it 'raises and logs ArgumentError for pub' do
      expect(NotificationManager).to receive(:error)
      processor.pubmed_addition('pub')
    end

    it 'raises and logs ArgumentError for PMID' do
      expect(pub).to receive(:pmid).and_return(nil)
      expect(NotificationManager).to receive(:error)
      processor.pubmed_addition(pub)
    end

    context 'with WOS Publication' do
      before do
        wos_pub.pmid = wos_record.pmid
        wos_pub.save!
      end

      it 'persists MESH headings' do
        expect(wos_pubmed_rec.pmid).to eq(wos_record.pmid.to_i) # ensure a wos_pubmed record exists
        processor.pubmed_addition(wos_pub)
        expect(wos_pub.reload.pub_hash).to include(:mesh_headings)
      end

      it 'persists PMC in identifier section of hash' do
        expect(wos_pub.publication_identifiers.where(identifier_type: 'pmc').count).to eq 0 # we not yet have a pmc row in publication identifier table
        expect(wos_pubmed_rec.pmid).to eq(wos_record.pmid.to_i) # ensure a wos_pubmed record exists
        processor.pubmed_addition(wos_pub)
        wos_pub.reload
        expect(wos_pub.pub_hash[:identifier]).to include(type: 'pmc', id: 'PMC1234567')
        expect(wos_pub.publication_identifiers.where(identifier_type: 'pmc').count).to eq 1 # we now have a pmc row in publication identifier table
      end

      it 'cannot retrieve a PMID record, try to delete stuff' do
        expect(PubmedSourceRecord).to receive(:for_pmid).and_return(nil)
        expect(Pubmed).to receive(:working?).and_return(false)
        processor.pubmed_addition(wos_pub)
      end

      it 'exceptions are logged' do
        expect(PubmedSourceRecord).to receive(:for_pmid).and_raise(RuntimeError)
        expect(NotificationManager).to receive(:error)
        processor.pubmed_addition(wos_pub)
      end
    end
  end

  describe '#pubmed_cleanup' do
    it 'raises and logs ArgumentError for pub' do
      expect(NotificationManager).to receive(:error)
      processor.pubmed_cleanup('pub')
    end

    it 'raises and logs ArgumentError for PMID' do
      expect(pub).to receive(:pmid).and_return(nil)
      expect(NotificationManager).to receive(:error)
      processor.pubmed_cleanup(pub)
    end

    context 'with WOS Publication' do
      before do
        wos_pub.pmid = wos_record.pmid
        wos_pub.save!
      end

      it 'do not remove PublicationIdentifier when Pubmed API is down' do
        expect(Pubmed).to receive(:working?).and_return(false)
        expect { processor.pubmed_cleanup(wos_pub) }.not_to change { wos_pub.reload.publication_identifiers.count }
      end

      it 'do not remove Publication.pmid when Pubmed API is down' do
        expect(Pubmed).to receive(:working?).and_return(false)
        expect { processor.pubmed_cleanup(wos_pub) }.not_to change { wos_pub.reload.pmid }
      end

      it 'remove PublicationIdentifier when Pubmed API is down' do
        expect(Pubmed).to receive(:working?).and_return(true)
        expect { processor.pubmed_cleanup(wos_pub) }.to change { wos_pub.reload.publication_identifiers.count }.by(-1)
      end

      it 'remove Publication.pmid when Pubmed API is down' do
        expect(Pubmed).to receive(:working?).and_return(true)
        expect { processor.pubmed_cleanup(wos_pub) }.to change { wos_pub.reload.pmid }
      end
    end
  end
end
