describe WebOfScience::ProcessRecords do
  let(:author) do
    # public data from
    # - https://stanfordwho.stanford.edu
    # - https://med.stanford.edu/profiles/russ-altman
    author = FactoryGirl.create(:author,
                                 preferred_first_name: 'Russ',
                                 preferred_last_name: 'Altman',
                                 preferred_middle_name: 'Biagio',
                                 email: 'Russ.Altman@stanford.edu',
                                 cap_import_enabled: true)
    # create some `author.alternative_identities`
    FactoryGirl.create(:author_identity,
                       author: author,
                       first_name: 'R',
                       middle_name: 'B',
                       last_name: 'Altman',
                       email: nil,
                       institution: 'Stanford University')
    FactoryGirl.create(:author_identity,
                       author: author,
                       first_name: 'Russ',
                       middle_name: nil,
                       last_name: 'Altman',
                       email: nil,
                       institution: nil)
    author
  end

  let(:medline_xml) { File.read('spec/fixtures/wos_client/medline_encoded_records.html') }
  let(:medline_records) { WebOfScience::Records.new(encoded_records: medline_xml) }

  let(:wos_record_uid) { 'WOS:000288663100014' }
  let(:wos_record_xml) { File.read('spec/fixtures/wos_client/wos_record_000288663100014.xml') }
  let(:wos_records_xml) { "<records>#{wos_record_xml}</records>" }
  let(:wos_records) { WebOfScience::Records.new(records: wos_records_xml) }
  let(:wos_records_links) do
    { 'WOS:000288663100014' => { 'pmid' => '21253920', 'doi' => '10.1007/s12630-011-9462-1' } }
  end

  let(:links_client) { Clarivate::LinksClient.new }
  let(:null_logger) { Logger.new('/dev/null') }

  before do
    allow(processor).to receive(:logger).and_return(null_logger)
    allow(processor).to receive(:links_client).and_return(links_client)
  end

  shared_examples '#execute' do
    # ---
    # Happy paths

    it 'works' do
      result = processor.execute
      expect(result).not_to be_nil
    end
    it 'returns an Array' do
      result = processor.execute
      expect(result).to be_an Array
    end
    it 'returns Array<String> with WosUIDs on success' do
      result = processor.execute
      uid_success = result & records.uids
      expect(uid_success).not_to be_empty
    end
    it 'creates new WebOfScienceSourceRecords' do
      expect { processor.execute }.to change { WebOfScienceSourceRecord.count }
    end
    it 'creates new Publications'
    it 'creates new PublicationIdentifiers'
    it 'creates new Contributions'

    # ---
    # Unhappy paths

    it 'raises ArgumentError for author' do
      expect { described_class.new('author', records) }.to raise_error(ArgumentError)
    end
    it 'raises ArgumentError for records' do
      expect { described_class.new(author, []) }.to raise_error(ArgumentError)
    end

    context 'save_wos_records fails' do
      before do
        allow(processor).to receive(:save_wos_records).and_raise(RuntimeError)
      end

      it 'does not create new WebOfScienceSourceRecords' do
        expect { processor.execute }.not_to change { WebOfScienceSourceRecord.count }
      end
      it 'logs errors' do
        expect(null_logger).to receive(:error)
        processor.execute
      end
      it 'returns an Array' do
        result = processor.execute
        expect(result).to be_an Array
      end
      it 'returns empty Array' do
        result = processor.execute
        expect(result).to be_empty
      end
    end
  end

  context 'with MEDLINE records' do
    subject(:processor) { described_class.new(author, records) }

    let(:records) { medline_records }

    # Note: medline records are not submitted to the links-API

    it_behaves_like '#execute'
  end

  context 'with WOS records' do
    subject(:processor) { described_class.new(author, records) }

    let(:records) { wos_records }

    before do
      allow(links_client).to receive(:links).with([wos_record_uid]).and_return(wos_records_links)
    end

    it_behaves_like '#execute'
  end
end