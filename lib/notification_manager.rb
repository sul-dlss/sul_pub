class NotificationManager
  def self.notify(e, message)
    Squash::Ruby.notify(e, notify_message: message) unless Settings.SQUASH.DISABLED
  end

  def self.handle_harvest_problem(e, message)
    notify(e, 'sciencewire_harvest_problem: ' + message)
  end

  def self.handle_authorship_pull_error(e, message)
    @cap_authorship_logger = Logger.new(Settings.CAP.AUTHORSHIP_API_LOG)
    @cap_authorship_logger.error message
    @cap_authorship_logger.error e.message
    @cap_authorship_logger.error e.backtrace.join("\n") if e.backtrace.present?

    notify(e, 'authorship_pull_error: ' + message)
  end

  def self.handle_pubmed_pull_error(e, message)
    @pubmed_logger = Logger.new(Settings.PUBMED.API_LOG)
    @pubmed_logger.error message
    @pubmed_logger.error e.message
    @pubmed_logger.error e.backtrace.join("\n") if e.backtrace.present?
    Rails.logger.warn e.inspect
    Rails.logger.info e.backtrace.join("\n") if e.backtrace.present?

    notify(e, 'pubmed_pull_error: ' + message)
  end
end
