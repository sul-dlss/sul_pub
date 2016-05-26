require 'spec_helper'

describe NotificationManager do
  let(:message) { 'this is an error message' }
  let(:exception) { double(Exception, message: message, backtrace: ['backtrace data']) }
  let(:null_logger) { Logger.new('/dev/null') }
  before do
    allow(Logger).to receive(:new).and_return(null_logger)
  end
  context '.notify_squash' do
    it 'notifies squash on errors' do
      Settings.SQUASH.DISABLED = false
      expect(Squash::Ruby).to receive(:notify).once
      described_class.notify_squash(exception, message)
    end
    it 'does NOT notify squash on errors if disabled' do
      Settings.SQUASH.DISABLED = true
      expect(Squash::Ruby).not_to receive(:notify)
      described_class.notify_squash(exception, message)
    end
  end
  context '.error' do
    context '.notify_squash' do
      it 'notifies on specific callees' do
        klasses = [
          ScienceWireHarvester, ScienceWireClient,
          PubmedHarvester, PubmedClient,
          CapAuthorsPoller, CapHttpClient
        ]
        expect(described_class).to receive(:notify_squash).exactly(klasses.length)
        klasses.map(&:new).each do |callee|
          described_class.error(exception, message, callee)
        end
      end
      it 'does not notify on generic error' do
        expect(Logger).not_to receive(:new)
        expect(described_class).not_to receive(:notify_squash)
        described_class.error(exception, message)
      end
      it 'notifies on internal exception during logging' do
        expect(Rails.logger).to receive(:warn).exactly(1).and_throw(:fake_error)
        expect(described_class).to receive(:notify_squash)
        described_class.error(exception, message, PubmedHarvester.new)
      end
    end
    context 'logger' do
      it 'logs to Rails console on generic error' do
        expect(Rails.logger).to receive(:error).exactly(3)
        described_class.error(exception, message)
      end
    end
  end
  context '.cap_authorship_logger' do
    before do
      described_class.class_variable_set(:@@cap_authorship_logger, nil)
    end
    it 'creates a single logger' do
      expect(Logger).to receive(:new).with(Settings.CAP.AUTHORSHIP_API_LOG).once
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
      expect(Logger).to receive(:new).with(Settings.PUBMED.API_LOG).once
      described_class.error(exception, message, PubmedHarvester.new)
      described_class.error(exception, message, PubmedClient.new)
    end
    it 'logs to two different loggers' do
      expect(Rails.logger).to receive(:warn).twice
      expect(Rails.logger).to receive(:info).twice
      expect(null_logger).to receive(:error).exactly(6)
      described_class.error(exception, message, PubmedHarvester.new)
      described_class.error(exception, message, PubmedClient.new)
    end
  end
end
