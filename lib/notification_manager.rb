class NotificationManager
	def self.handle_harvest_problem(e, message)
		sw_harvest_logger = Logger.new(Rails.root.join('log', 'sw_harvest.log'))
		sw_harvest_logger.info message
	    sw_harvest_logger.error e.message
	    sw_harvest_logger.error e.backtrace
	    puts e.message
	    puts e.backtrace.inspect
	    #todo send email here
	end

	def self.handle_authorship_pull_error(e, message)
      	@cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
      	@cap_authorship_logger.error message
      	@cap_authorship_logger.error e.message
      	@cap_authorship_logger.error e.backtrace
      	puts e.message
      	puts e.backtrace
      	#todo send email here
	end

end