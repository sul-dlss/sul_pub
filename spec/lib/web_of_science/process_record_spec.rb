describe WebOfScience::ProcessRecord, :vcr do
  subject(:processor) { described_class.new(author, wos_src_record) }

  let(:author) { create :russ_altman }
  let(:wos_record) do
    rec = WebOfScience::Record.new(record: record_xml)
    rec.identifiers.update(links)
    rec
  end
  let(:wos_src_record) { wos_record.source_record_find_or_create }

  before do
    null_logger = Logger.new('/dev/null')
    allow(WebOfScience).to receive(:logger).and_return(null_logger)
    expect(wos_src_record).to be_a WebOfScienceSourceRecord
  end

  shared_examples '#execute' do
    # ---
    # Happy paths

    it 'creates new Publications' do
      expect { processor.execute }.to change { Publication.count }
    end
    it 'creates Publications with WOS attributes' do
      processor.execute
      pub = Publication.find_by(wos_uid: wos_src_record.uid)
      expect(pub).not_to be_nil
      expect(pub.pub_hash[:provenance]).to eq Settings.wos_source
    end

    it 'creates new PublicationIdentifiers' do
      expect { processor.execute }.to change { PublicationIdentifier.count }
    end

    it 'creates new Contributions' do
      expect { processor.execute }.to change { Contribution.count }
    end
    it 'creates new contribution in the pub_hash[:authorship]' do
      processor.execute
      pub = Publication.find_by(wos_uid: wos_src_record.uid)
      expect(pub.pub_hash).to include(:authorship)
    end

    # ---
    # Unhappy paths

    it 'raises ArgumentError for author' do
      expect { described_class.new('author', wos_src_record) }.to raise_error(ArgumentError)
    end
    it 'raises ArgumentError for record' do
      expect { described_class.new(author, 'wrong-stuff') }.to raise_error(ArgumentError)
    end

    context 'create_publication fails' do
      before do
        allow(Publication).to receive(:new).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'does not create new Publications' do
        expect { processor.execute }.not_to change { Publication.count }
      end
      it 'does not create new Contributions' do
        expect { processor.execute }.not_to change { Contribution.count }
      end
      it 'logs errors' do
        expect(NotificationManager).to receive(:error).at_least(:once)
        processor.execute
      end
    end
  end

  # ---
  # MESH headings - integration specs
  # Note: not all PubMed/MEDLINE records contain MESH headings, so the
  # spec example record was chosen to contain or fetch MESH headings

  shared_examples 'pubs_with_pmid_have_mesh_headings' do
    # The specs calling this must use a record with a PMID
    # - any MEDLINE record has a PMID
    # - for WOS records, they may not have PMID, but they could get one from the links service in the processing
    it 'persists PMID and publication.pub_hash has MESH headings' do
      processor.execute
      pub = Publication.find_by(wos_uid: wos_src_record.uid)
      expect(pub.pmid).to be_an Integer
      expect(pub.pub_hash).to include(:mesh_headings)
    end
  end

  context 'with MEDLINE record' do
    # Note: "MEDLINE:26776186" has a PMID and MESH headings
    let(:record_uid) { 'MEDLINE:26776186' }
    let(:record_xml) { File.read('spec/fixtures/wos_client/medline_record_26776186.xml') }
    let(:links) { {} } # medline records are not submitted to the links-API

    it_behaves_like '#execute'
    it_behaves_like 'pubs_with_pmid_have_mesh_headings'
  end

  context 'with WOS record' do
    # Note: "WOS:000288663100014" has a PMID and it gets MESH headings from PubMed
    let(:pmid) { '21253920' }
    let(:pubmed_xml) { File.read("spec/fixtures/pubmed/pubmed_record_#{pmid}.xml") }
    let(:record_uid) { 'WOS:000288663100014' }
    let(:record_xml) { File.read('spec/fixtures/wos_client/wos_record_000288663100014.xml') }
    let(:links) { { 'pmid' => pmid, 'doi' => '10.1007/s12630-011-9462-1' } }

    before do
      pub_doc = Nokogiri::XML(pubmed_xml)
      PubmedSourceRecord.create_pubmed_source_record(pmid, pub_doc)
    end

    it_behaves_like '#execute'
    it_behaves_like 'pubs_with_pmid_have_mesh_headings'

    context 'PubMed integration fails' do
      # only WOS records can be supplemented by PubMed data
      # any failure is not catastrophic - just log it
      before do
        allow(PubmedSourceRecord).to receive(:for_pmid).and_raise(RuntimeError)
      end

      it 'continues to create new Publications' do
        expect { processor.execute }.to change { Publication.count }
      end
      it 'logs errors' do
        expect(NotificationManager).to receive(:error)
        processor.execute
      end
    end
  end
end
