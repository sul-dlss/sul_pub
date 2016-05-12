require 'spec_helper'

describe NotificationManager do
  let(:message) { 'this is an error message' }
  let(:exception) { double(Exception, message: message, backtrace: ['backtrace data']) }
  context '.notify' do
    it 'notifies squash on errors' do
      Settings.SQUASH.DISABLED = false
      expect(Squash::Ruby).to receive(:notify).once
      described_class.notify(exception, message)
    end
    it 'does NOT notify squash on errors if disabled' do
      Settings.SQUASH.DISABLED = true
      expect(Squash::Ruby).not_to receive(:notify)
      described_class.notify(exception, message)
    end
  end
  context '.handle_harvest_problem' do
    it 'notifies' do
      expect(described_class).to receive(:notify).once
      described_class.handle_harvest_problem(exception, message)
    end
  end
  context '.handle_authorship_pull_error' do
    it 'creates a logger' do
      described_class.class_variable_set(:@@cap_authorship_logger, nil)
      error_logger = Logger.new('/dev/null')
      expect(described_class).to receive(:cap_authorship_logger).exactly(3).and_call_original
      expect(Logger).to receive(:new).with(Settings.CAP.AUTHORSHIP_API_LOG).once.and_return(error_logger)
      described_class.handle_authorship_pull_error(exception, message)
    end
    it 'notifies and logs' do
      error_logger = Logger.new('/dev/null')
      expect(described_class).to receive(:cap_authorship_logger).exactly(3).and_return(error_logger)
      expect(error_logger).to receive(:error).exactly(3)
      expect(described_class).to receive(:notify).once
      described_class.handle_authorship_pull_error(exception, message)
    end
  end
  context '.handle_pubmed_pull_error' do
    it 'creates a logger' do
      described_class.class_variable_set(:@@pubmed_logger, nil)
      error_logger = Logger.new('/dev/null')
      expect(described_class).to receive(:pubmed_logger).exactly(3).and_call_original
      expect(Logger).to receive(:new).with(Settings.PUBMED.API_LOG).once.and_return(error_logger)
      described_class.handle_pubmed_pull_error(exception, message)
    end
    it 'notifies and logs twice' do
      rails_logger = Logger.new('/dev/null')
      expect(Rails).to receive(:logger).twice.and_return(rails_logger)
      expect(rails_logger).to receive(:warn).once
      expect(rails_logger).to receive(:info).once
      error_logger = Logger.new('/dev/null')
      expect(described_class).to receive(:pubmed_logger).exactly(3).and_return(error_logger)
      expect(error_logger).to receive(:error).exactly(3)
      expect(described_class).to receive(:notify).once
      described_class.handle_pubmed_pull_error(exception, message)
    end
  end
end
