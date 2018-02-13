describe WebOfScience::AuthorHarvestJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(author) }

  let(:queue) { 'wos_author_harvest' }

  let(:author) { create :russ_altman }

  before do
    allow(Settings.WOS).to receive(:enabled).and_return(false) # default
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'queues the job' do
    ActiveJob::Base.queue_adapter = :test
    expect { job }
      .to have_enqueued_job(described_class)
      .with(author)
      .on_queue(queue)
  end

  it 'is in wos_author_harvest queue' do
    expect(described_class.new.queue_name).to eq(queue)
  end

  context 'WebOfScience is disabled' do
    it 'executes perform without calling harvester' do
      ActiveJob::Base.queue_adapter = :test
      expect(WebOfScience).not_to receive(:harvester)
      perform_enqueued_jobs { job }
    end
  end

  context 'WebOfScience is enabled' do
    it 'executes perform by calling harvester' do
      ActiveJob::Base.queue_adapter = :test
      expect(Settings.WOS).to receive(:enabled).and_return(true)
      expect(WebOfScience.harvester).to receive(:process_author)
      perform_enqueued_jobs { job }
    end
  end
end
