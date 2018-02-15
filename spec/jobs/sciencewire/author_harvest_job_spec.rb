describe ScienceWire::AuthorHarvestJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(author) }

  let(:queue) { 'sw_author_harvest' }

  let(:author) { create :russ_altman }

  before do
    allow(Settings.SCIENCEWIRE).to receive(:enabled).and_return(false) # default
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

  it 'is in sw_author_harvest queue' do
    expect(described_class.new.queue_name).to eq(queue)
  end

  context 'ScienceWire is disabled' do
    it 'executes perform without calling sciencewire' do
      ActiveJob::Base.queue_adapter = :test
      expect(ScienceWireHarvester).not_to receive(:new)
      perform_enqueued_jobs { job }
    end
  end

  context 'ScienceWire is enabled' do
    it 'executes perform using sciencewire' do
      ActiveJob::Base.queue_adapter = :test
      allow(Settings.SCIENCEWIRE).to receive(:enabled).and_return(true)
      harvester = ScienceWireHarvester.new
      allow(harvester).to receive(:harvest_pubs_for_author_ids).with(author.id)
      expect(ScienceWireHarvester).to receive(:new).and_return(harvester)
      perform_enqueued_jobs { job }
    end
  end
end
