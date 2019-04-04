describe AuthorHarvestJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(author.cap_profile_id) }

  let(:queue) { 'default' }

  let(:author) { create :russ_altman }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'queues the job' do
    expect { job }
      .to have_enqueued_job(described_class)
      .with(author.cap_profile_id)
      .on_queue(queue)
  end

  it 'is in default queue' do
    expect(described_class.new.queue_name).to eq(queue)
  end

  context 'WebOfScience is disabled' do
    it 'executes perform without calling WoS but still calls Pubmed' do
      allow(Settings.WOS).to receive(:enabled).and_return(false)
      expect(WebOfScience.harvester).not_to receive(:process_author).with(author, {})
      expect(Pubmed.harvester).to receive(:process_author).with(author, {})
      perform_enqueued_jobs { job }
    end
  end

  context 'WebOfScience is enabled' do
    it 'executes perform calling WoS and Pubmed' do
      allow(Settings.WOS).to receive(:enabled).and_return(true)
      expect(WebOfScience.harvester).to receive(:process_author).with(author, {})
      expect(Pubmed.harvester).to receive(:process_author).with(author, {})
      perform_enqueued_jobs { job }
    end
  end

  # it 'handles no results error' do
  #   allow(MyService).to receive(:call).and_raise(NoResultsError)
  #
  #   perform_enqueued_jobs do
  #     expect_any_instance_of(described_class)
  #       .to receive(:retry_job).with(wait: 10.minutes, queue: :default)
  #
  #     job
  #   end
  # end
end
