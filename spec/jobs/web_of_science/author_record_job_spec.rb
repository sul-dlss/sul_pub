describe WebOfScience::AuthorRecordJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(author, wos_src_record) }

  let(:queue) { 'wos_author_record' }

  let(:author) { create :russ_altman }

  # Similar spec fixtures are used in specs for WebOfScience::ProcessRecord
  # Note: "WOS:000288663100014" has a PMID and it gets MESH headings from PubMed
  let(:pmid) { '21253920' }
  let(:pubmed_xml) { File.read("spec/fixtures/pubmed/pubmed_record_#{pmid}.xml") }
  let(:record_uid) { 'WOS:000288663100014' }
  let(:record_xml) { File.read('spec/fixtures/wos_client/wos_record_000288663100014.xml') }
  let(:record) { WebOfScience::Record.new(record: record_xml) }
  let(:links) { { 'pmid' => pmid, 'doi' => '10.1007/s12630-011-9462-1' } }
  let(:wos_src_record) do
    record.identifiers.update(links)
    record.source_record_find_or_create
  end

  let(:processor) { WebOfScience::ProcessRecord.new(author, wos_src_record) }

  before do
    allow(Settings.WOS).to receive(:enabled).and_return(false) # default
    allow(WebOfScience::ProcessRecord).to receive(:new).with(author, wos_src_record).and_return(processor)
    expect(wos_src_record).to be_a WebOfScienceSourceRecord
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'queues the job' do
    ActiveJob::Base.queue_adapter = :test
    expect { job }
      .to have_enqueued_job(described_class)
      .with(author, wos_src_record)
      .on_queue(queue)
  end

  it 'is in wos_author_harvest queue' do
    expect(described_class.new.queue_name).to eq(queue)
  end

  context 'WebOfScience is disabled' do
    it 'executes perform without calling harvester' do
      ActiveJob::Base.queue_adapter = :test
      expect(WebOfScience::ProcessRecord).not_to receive(:new)
      perform_enqueued_jobs { job }
    end
  end

  context 'WebOfScience is enabled' do
    it 'executes perform by using WebOfScience::ProcessRecord' do
      ActiveJob::Base.queue_adapter = :test
      expect(Settings.WOS).to receive(:enabled).and_return(true)
      expect(processor).to receive(:execute)
      perform_enqueued_jobs { job }
    end
  end
end
