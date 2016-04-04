class NotificationManager
  def self.handle_harvest_problem(_e, _message)
    # Error should get logged at rescue time
    # TODO: send email here
  end

  def self.handle_authorship_pull_error(e, message)
    @cap_authorship_logger = Logger.new(Settings.CAP.AUTHORSHIP_API_LOG)
    @cap_authorship_logger.error message
    @cap_authorship_logger.error e.message
    @cap_authorship_logger.error e.backtrace.join("\n")
    # TODO: send email here
  end

  def self.handle_pubmed_pull_error(e, message)
    @pubmed_logger = Logger.new(Settings.PUBMED.API_LOG)
    @pubmed_logger.error message
    @pubmed_logger.error e.message
    @pubmed_logger.error e.backtrace.join("\n")
    Rails.logger.warn e.inspect
    Rails.logger.info e.backtrace.join("\n")
  end
end
