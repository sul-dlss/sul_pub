class NotificationManager

	def self.handle_harvest_problem(e, message)
    # Error should get logged at rescue time
	  #todo send email here
	end

	def self.handle_authorship_pull_error(e, message)
  	@cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
  	@cap_authorship_logger.error message
  	@cap_authorship_logger.error e.message
  	@cap_authorship_logger.error e.backtrace.join("\n")
  	#todo send email here
	end

	def self.handle_pubmed_pull_error(e, message)
  	@pubmed_logger = Logger.new(Rails.root.join('log', 'pubmed_api.log'))
  	@pubmed_logger.error message
  	@pubmed_logger.error e.message
  	@pubmed_logger.error e.backtrace.join("\n")
  	puts e.inspect
  	puts e.backtrace.join("\n")
	end



end