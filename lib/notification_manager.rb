class NotificationManager

  class << self

    def notify_squash(e, message)
      Squash::Ruby.notify(e, notify_message: message) unless Settings.SQUASH.DISABLED
    end

    ##
    # Handles notification of errors with behavior based on the callee
    #
    # @param [Exception] `e` -- the original exception
    # @param [String] `message` -- human-readable message
    # @param [Class] `callee` -- the callee object
    # @param [Boolean] `use_squash` -- if true, sends `e` to Squash
    def error(e, message, callee = nil, use_squash = true)
      log_message = callee.class.name + ': ' + message

      case callee
      when ScienceWireHarvester, ScienceWireClient
        log_exception(sciencewire_logger, log_message, e)
      when PubmedHarvester, PubmedClient
        log_exception(pubmed_logger, log_message, e)
      when CapAuthorsPoller, CapHttpClient
        log_exception(cap_logger, log_message, e)
      else
        log_exception(Rails.logger, log_message, e)
        use_squash = false # only log error to Rails console
      end
    rescue => e2
      log_exception(Rails.logger, e2.message, e2)
    ensure
      notify_squash(e, log_message) if use_squash
    end

    private

    # rubocop:disable Style/ClassVars
    def pubmed_logger
      @@pubmed_logger ||= Logger.new(Settings.PUBMED.API_LOG)
    end
    # rubocop:enable Style/ClassVars

    # rubocop:disable Style/ClassVars
    def cap_logger
      @@cap_logger ||= Logger.new(Settings.CAP.API_LOG)
    end
    # rubocop:enable Style/ClassVars

    # rubocop:disable Style/ClassVars
    def sciencewire_logger
      @@sciencewire_logger ||= Logger.new(Settings.SCIENCEWIRE.API_LOG)
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
