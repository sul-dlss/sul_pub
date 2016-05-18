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
    def error(e, message, callee = nil, use_squash = true)
      log_message = callee.class.name + ': ' + message

      case callee
      when ScienceWireHarvester, ScienceWireClient
        # no logging -- TODO: why?
      when PubmedHarvester, PubmedClient
        pubmed_logger.error log_message
        pubmed_logger.error e.message
        pubmed_logger.error e.backtrace.join("\n") if e.backtrace.present?
        Rails.logger.warn e.inspect
        Rails.logger.info e.backtrace.join("\n") if e.backtrace.present?
      when CapAuthorsPoller, CapHttpClient
        cap_authorship_logger.error log_message
        cap_authorship_logger.error e.message
        cap_authorship_logger.error e.backtrace.join("\n") if e.backtrace.present?
      else
        Rails.logger.error log_message
        Rails.logger.error e.inspect
        Rails.logger.error e.backtrace.join("\n") if e.backtrace.present?
        use_squash = false # only log error to Rails console
      end
    rescue => e2
      Rails.logger.error e2.inspect
      Rails.logger.error e2.backtrace.join("\n") if e2.backtrace.present?
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
    def cap_authorship_logger
      @@cap_authorship_logger ||= Logger.new(Settings.CAP.AUTHORSHIP_API_LOG)
    end
    # rubocop:enable Style/ClassVars
  end
end
