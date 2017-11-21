class NotificationManager

  class << self
    ##
    # Handles notification of errors with behavior based on the callee
    #
    # @param [Exception] e -- the original exception
    # @param [String] message -- human-readable message
    # @param [Class] callee -- the callee object
    def error(e, message, callee = nil)
      log_message = callee.class.name + ': ' + message

      case callee
      when ScienceWireHarvester, ScienceWireClient, SciencewireSourceRecord
        log_exception(sciencewire_logger, log_message, e)
      when PubmedHarvester, PubmedClient, PubmedSourceRecord
        log_exception(pubmed_logger, log_message, e)
      when CapAuthorsPoller, CapHttpClient
        log_exception(cap_logger, log_message, e)
      when WebOfScience::Client, WebOfScience::Harvester, WebOfScience::ProcessRecords, WebOfScience::Record
        log_exception(WebOfScience.logger, log_message, e)
      else
        log_exception(Rails.logger, log_message, e)
      end
    rescue => e2
      log_exception(Rails.logger, e2.message, e2)
    ensure
      Honeybadger.notify(e, context: { message: log_message })
    end

    # rubocop:disable Style/ClassVars
    def pubmed_logger
      @@pubmed_logger ||= Logger.new(Settings.PUBMED.LOG)
    end

    def cap_logger
      @@cap_logger ||= Logger.new(Settings.CAP.LOG)
    end

    def sciencewire_logger
      @@sciencewire_logger ||= Logger.new(Settings.SCIENCEWIRE.LOG)
    end
    # rubocop:enable Style/ClassVars

    # Helper method to log exceptions in a consistent way
    def log_exception(logger, message, e)
      logger.error message
      logger.error e.inspect
      logger.error e.backtrace.join("\n") if e.backtrace.present?
    end
  end
end
