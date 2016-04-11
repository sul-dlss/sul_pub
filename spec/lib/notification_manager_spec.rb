require 'spec_helper'

describe NotificationManager do
  let(:message) { 'this is an error message' }
  let(:exception) { double(Exception, message: message, backtrace: ['backtrace data']) }
  let(:error_logger) { double(Logger, error: -> {}) }
  let(:empty_logger) { Logger.new('/dev/null') }
  context '.notify' do
    it 'notifies squash on errors' do
      Settings.SQUASH.DISABLED = false
      expect(Squash::Ruby).to receive(:notify).once
      subject.class.notify(exception, message)
    end
    it 'does NOT notify squash on errors if disabled' do
      Settings.SQUASH.DISABLED = true
      expect(Squash::Ruby).not_to receive(:notify)
      subject.class.notify(exception, message)
    end
  end
  context '.handle_harvest_problem' do
    it 'notifies' do
      expect(subject.class).to receive(:notify).once
      subject.class.handle_harvest_problem(exception, message)
    end
  end
  context '.handle_authorship_pull_error' do
    it 'notifies and logs' do
      expect(Logger).to receive(:new).with(Settings.CAP.AUTHORSHIP_API_LOG).once.and_return(error_logger)
      expect(error_logger).to receive(:error).exactly(3)
      expect(subject.class).to receive(:notify).once
      subject.class.handle_authorship_pull_error(exception, message)
    end
  end
  context '.handle_pubmed_pull_error' do
    it 'notifies and logs twice' do
      expect(Rails).to receive(:logger).twice.and_return(empty_logger)
      expect(empty_logger).to receive(:warn).once
      expect(empty_logger).to receive(:info).once
      expect(Logger).to receive(:new).with(Settings.PUBMED.API_LOG).once.and_return(error_logger)
      expect(error_logger).to receive(:error).exactly(3)
      expect(subject.class).to receive(:notify).once
      subject.class.handle_pubmed_pull_error(exception, message)
    end
  end
end
