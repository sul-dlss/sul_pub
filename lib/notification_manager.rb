class NotificationManager

  class << self
    def notify(e, message)
      Squash::Ruby.notify(e, notify_message: message) unless Settings.SQUASH.DISABLED
    end

    def handle_harvest_problem(e, message)
      notify(e, 'sciencewire_harvest_problem: ' + message)
    end

    def handle_authorship_pull_error(e, message)
      cap_authorship_logger.error message
      cap_authorship_logger.error e.message
      cap_authorship_logger.error e.backtrace.join("\n") if e.backtrace.present?

      notify(e, 'authorship_pull_error: ' + message)
    end

    def handle_pubmed_pull_error(e, message)
      pubmed_logger.error message
      pubmed_logger.error e.message
      pubmed_logger.error e.backtrace.join("\n") if e.backtrace.present?
      Rails.logger.warn e.inspect
      Rails.logger.info e.backtrace.join("\n") if e.backtrace.present?

      notify(e, 'pubmed_pull_error: ' + message)
    end

    private

      def pubmed_logger
        @pubmed_logger ||= Logger.new(Settings.PUBMED.API_LOG)
      end

      def cap_authorship_logger
        @cap_authorship_logger ||= Logger.new(Settings.CAP.AUTHORSHIP_API_LOG)
      end
  end
end
