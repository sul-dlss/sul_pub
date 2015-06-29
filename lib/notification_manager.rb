class NotificationManager
  def self.handle_harvest_problem(_e, _message)
    # Error should get logged at rescue time
    # TODO: send email here
  end

  def self.handle_authorship_pull_error(e, message)
    @cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
    @cap_authorship_logger.error message
    @cap_authorship_logger.error e.message
    @cap_authorship_logger.error e.backtrace.join("\n")
    # TODO: send email here
  end

  def self.handle_pubmed_pull_error(e, message)
    @pubmed_logger = Logger.new(Rails.root.join('log', 'pubmed_api.log'))
    @pubmed_logger.error message
    @pubmed_logger.error e.message
    @pubmed_logger.error e.backtrace.join("\n")
    Rails.logger.warn e.inspect
    Rails.logger.info e.backtrace.join("\n")
  end
end
