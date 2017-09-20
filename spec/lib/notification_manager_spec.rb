
describe NotificationManager do
  let(:message) { 'this is an error message' }
  let(:exception) { double(Exception, message: message, backtrace: ['backtrace data']) }
  let(:null_logger) { Logger.new('/dev/null') }
  before do
    allow(Logger).to receive(:new).and_return(null_logger)
  end
  context '.error' do
    it 'notifies on internal exception during logging' do
      expect(described_class).to receive(:log_exception).with(duck_type(:error), /PubmedHarvester/, duck_type(:message)).and_raise(RuntimeError.new)
      expect(described_class).to receive(:log_exception).with(duck_type(:error), 'RuntimeError', duck_type(:message)).and_call_original
      expect(Honeybadger).to receive(:notify)
      described_class.error(exception, message, PubmedHarvester.new)
    end

    context 'logger' do
      it 'logs to Rails console on generic error' do
        expect(Rails.logger).to receive(:error).exactly(3)
        described_class.error(exception, message)
      end
    end
  end
  context '.cap_logger' do
    before do
      described_class.class_variable_set(:@@cap_logger, nil)
    end
    it 'creates a single logger' do
      expect(Logger).to receive(:new).with(Settings.CAP.LOG).once
      described_class.error(exception, message, CapAuthorsPoller.new)
      described_class.error(exception, message, CapHttpClient.new)
    end
    it 'logs errors' do
      expect(null_logger).to receive(:error).exactly(6)
      described_class.error(exception, message, CapAuthorsPoller.new)
      described_class.error(exception, message, CapHttpClient.new)
    end
  end
  context '.pubmed_logger' do
    before do
      described_class.class_variable_set(:@@pubmed_logger, nil)
    end
    it 'creates a single logger' do
      expect(Logger).to receive(:new).with(Settings.PUBMED.LOG).once
      described_class.error(exception, message, PubmedHarvester.new)
      described_class.error(exception, message, PubmedClient.new)
    end
    it 'logs errors' do
      expect(null_logger).to receive(:error).exactly(6)
      described_class.error(exception, message, PubmedHarvester.new)
      described_class.error(exception, message, PubmedClient.new)
    end
  end
  context '.sciencewire_logger' do
    before do
      described_class.class_variable_set(:@@sciencewire_logger, nil)
    end
    it 'creates a single logger' do
      expect(Logger).to receive(:new).with(Settings.SCIENCEWIRE.LOG).once
      described_class.error(exception, message, ScienceWireHarvester.new)
      described_class.error(exception, message, ScienceWireClient.new)
    end
    it 'logs errors' do
      expect(null_logger).to receive(:error).exactly(6)
      described_class.error(exception, message, ScienceWireHarvester.new)
      described_class.error(exception, message, ScienceWireClient.new)
    end
  end
end
