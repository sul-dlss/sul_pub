# frozen_string_literal: true

describe WebOfScience::ProcessRecords, :vcr do
  subject(:processor) { described_class.new(author, records) }

  let(:author) { create :russ_altman }
  let(:records) { WebOfScience::Records.new(records: "<records>#{record_xml}</records>") }
  let(:record_xml) { File.read('spec/fixtures/wos_client/wos_record_000288663100014.xml') }
  let(:links_client) { Clarivate::LinksClient.new }
  let(:uids) { records.uids }
  let(:new_pubs) { Publication.where(wos_uid: uids) }
  let(:new_pub) { new_pubs.first }
  let(:wos_records_links) do
    { 'WOS:000288663100014' => { 'pmid' => '21253920', 'doi' => '10.1007/s12630-011-9462-1' } }
  end

  before do
    allow(WebOfScience).to receive(:logger).and_return(Logger.new('/dev/null'))
    allow(WebOfScience).to receive(:links_client).and_return(links_client)
  end

  shared_examples '#execute' do
    # Happy paths
    it 'returns Array<String> with WosUIDs on success' do
      result = processor.execute
      expect(result).to all(be_a(String))
      expect(result & records.uids).not_to be_empty
    end

    it 'creates new WebOfScienceSourceRecords, Publications, PublicationIdentifiers, Contributions' do
      expect { processor.execute }
        .to change(WebOfScienceSourceRecord, :count)
        .and change(Publication, :count)
        .and change(PublicationIdentifier, :count)
        .and change { author.contributions.count }
    end

    it 'creates Publications with WOS attributes' do
      processor.execute
      expect(new_pubs.size).to eq uids.size # i.e., 1
      expect(new_pub).not_to be_nil
      expect(new_pub.pub_hash).to include(provenance: Settings.wos_source, authorship: Array)
    end

    # Unhappy paths
    it 'raises ArgumentError for bad params' do
      expect { described_class.new('author', records) }.to raise_error(ArgumentError)
      expect { described_class.new(author, []) }.to raise_error(ArgumentError)
    end

    it 'raises RuntimeError when Settings.WOS.ACCEPTED_DBS.empty?' do
      allow(Settings.WOS).to receive(:ACCEPTED_DBS).and_return([])
      expect { described_class.new(author, records) }.to raise_error(RuntimeError)
    end

    context 'save_wos_records fails' do
      before { expect(WebOfScienceSourceRecord).to receive(:create!).and_raise(ActiveRecord::RecordInvalid) }

      it 'does not create new WebOfScienceSourceRecords' do
        expect { processor.execute }.not_to change(WebOfScienceSourceRecord, :count)
      end

      it 'returns empty Array' do
        expect(processor.execute).to eq []
      end

      it_behaves_like 'error_logger'
    end

    context 'create_publication fails' do
      before { allow(Publication).to receive(:create!).and_raise(ActiveRecord::RecordInvalid) }

      it 'does not create new Publications, Contributions' do
        expect { processor.execute }.not_to change { [Publication.count, Contribution.count] }
      end

      it 'returns empty Array' do
        expect(processor.execute).to eq []
      end

      it_behaves_like 'error_logger'
    end
  end

  # MESH headings - integration specs
  # Note: not all PubMed/MEDLINE records contain MESH headings, so the
  # spec example records were chosen to contain or fetch MESH headings

  shared_examples 'pubs_with_pmid_have_mesh_headings' do
    # The spec example records calling this must be associated with a PMID
    # - for MEDLINE records, they have a PMID
    # - for WOS records, they may not have PMID, but they could get one from the links service in the processing
    it 'persists PMID and publication.pub_hash has MESH headings' do
      processor.execute
      expect(new_pubs.size).to eq uids.size # i.e., 1
      expect(new_pub.pmid).to be_an Integer
      expect(new_pub.pub_hash).to include(mesh_headings: Array)
    end
  end

  shared_examples 'error_logger' do
    describe 'upon exception' do
      it 'logs errors' do
        expect(NotificationManager).to receive(:error).at_least(:once)
        processor.execute
      end
    end
  end

  shared_examples 'fail_forward' do
    describe 'continues' do
      it 'creates new Publications' do
        expect { processor.execute }.to change(Publication, :count)
      end

      it_behaves_like 'error_logger'
    end
  end

  context 'with MEDLINE records' do
    # NOTE: "MEDLINE:26776186" has a PMID and MESH headings
    # Note: medline records are not submitted to the links-API
    let(:record_xml) { File.read('spec/fixtures/wos_client/medline_record_26776186.xml') }

    it_behaves_like '#execute'
    it_behaves_like 'pubs_with_pmid_have_mesh_headings'
  end

  context 'with WOS records' do
    # NOTE: "WOS:000288663100014" has a PMID and it gets MESH headings from PubMed
    before do
      allow(links_client).to receive(:links).with(['WOS:000288663100014']).and_return(wos_records_links)
    end

    it_behaves_like '#execute'
    it_behaves_like 'pubs_with_pmid_have_mesh_headings'

    # only WOS records can be supplemented by PubMed data or links service
    # these failures are not catastrophic - just log it
    context 'PubMed integration fails' do
      before { allow(PubmedSourceRecord).to receive(:for_pmid).and_raise(RuntimeError) }

      it_behaves_like 'fail_forward'
    end

    context 'WOS links fail' do
      before { allow(links_client).to receive(:links).and_raise(RuntimeError) }

      it_behaves_like 'fail_forward'
    end
  end

  context 'with records from excluded databases' do
    let(:record_xml) do
      File.read('spec/fixtures/wos_client/wos_record_000288663100014.xml')
          .gsub('WOS', 'EXCLUDED')
    end

    it 'does not create new WebOfScienceSourceRecords' do
      expect { processor.execute }.not_to change(WebOfScienceSourceRecord, :count)
    end

    it 'filters out excluded records' do
      expect(processor).not_to receive(:save_wos_records)
      expect(processor.execute).to be_empty
    end
  end

  # This scenario includes when 2nd author is associated w/ a Pub that was already fetched for another author
  context 'WebOfScienceSourceRecord exists' do
    let(:author) { create :author }
    let(:wssr) { records.first.find_or_create_model }

    before { records.first.find_or_create_model }

    context 'Publication does not' do
      before { allow(links_client).to receive(:links).and_return({}) }

      describe 'backfills' do
        it 'does not duplicate WebOfScienceSourceRecord' do
          expect { processor.execute }.not_to change(WebOfScienceSourceRecord, :count)
        end

        it 'adds new Publications and Contributions' do
          expect { processor.execute }.to change { author.contributions.count }.from(0).to(1)
          expect(Publication.find_by(wos_uid: records.first.uid)).not_to be_nil
        end

        it 'associates the existing source record' do
          expect { processor.execute }.to change { wssr.reload.publication }.from(nil).to(Publication)
        end
      end
    end

    context 'matching non-WOS Publication also exists' do
      # this is a pain to setup.  kludge in the pmid to the fixture XML literal
      let(:wos_rec) do
        WebOfScience::Record.new(record: record_xml.gsub(/<identifiers>/,
                                                         %(<identifiers><identifier type='pmid' value='21253920'/>)))
      end
      let(:records) { WebOfScience::Records.new(records: "<records>#{wos_rec.to_xml}</records>") }
      let(:pub_hash) do
        {
          type: 'article',
          identifier: [{ type: 'pmid', id: '21253920', url: 'whatever' }, { type: 'doi', id: 'ABCXYZ', url: 'theother' }]
        }
      end
      let(:pub) do
        build :publication, sciencewire_id: 123, pmid: '21253920', pubhash_needs_update: true,
                            pub_hash: pub_hash
      end
      let(:uid) { records.first.uid }

      before do
        allow(links_client).to receive(:links).and_return(wos_records_links)
        wos_rec.identifiers.update('pmid' => '21253920')
        pub.save!
      end

      describe 'record.matching_publication' do
        let(:match) { PublicationIdentifier.find_by(identifier_type: 'pmid', identifier_value: '21253920') }
        let(:other_id) { create :doi_pub_id, identifier_value: '10.1007/s12630-011-9462-1' }

        it 'finds the Publication by non-WOS IDs' do
          expect(PublicationIdentifier.where(identifier_type: 'WosUID').count).to eq 0
          expect(match).not_to be_nil
          expect(match.publication.wos_uid).to be_nil
          expect(wos_rec.matching_publication).not_to be_nil
        end

        it 'adheres to a priority on matching' do
          expect(wos_rec.doi).to eq(other_id.identifier_value)
          expect(PublicationIdentifier.where(identifier_type: 'doi').count).to eq 2
          expect(wos_rec.matching_publication).to eq(other_id.publication) # match on DOI before PMID
          expect(pub).not_to eq(other_id.publication)
        end
      end

      describe 'backfills' do
        it 'does not duplicate WebOfScienceSourceRecord' do
          expect { processor.execute }.not_to change(WebOfScienceSourceRecord, :count)
        end

        it 'adds new Contribution' do
          expect { processor.execute }.to change { author.contributions.count }.from(0).to(1)
          expect(Publication.find_by(wos_uid: records.first.uid)).not_to be_nil
        end

        it 'sets wos_uid on the Pub' do
          expect { processor.execute }.to change { pub.reload.wos_uid }.from(nil).to(uid)
        end

        it 'associates source record to existing Pub' do
          expect { processor.execute }.to change {
                                            WebOfScienceSourceRecord.find_by(uid: uid).publication
                                          }.from(nil).to(pub)
        end
      end
    end
  end
end
