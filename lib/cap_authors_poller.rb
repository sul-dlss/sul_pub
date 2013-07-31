require 'dotiw'
class CapAuthorsPoller
	include ActionView::Helpers::DateHelper

	def get_authorship_data
  		
  		begin
  			@cap_http_client = CapHttpClient.new 
  			poll_since = '' #(Time.now - 172.hours).iso8601(3)
  			page_size = 1000
  			page_count = 0

  			@new_or_changed_authors_to_harvest_queue = []

			@cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
	  		@cap_authorship_logger.info "Started authorship import - #{DateTime.now}" 
	  		
	  		@last_page = false
	  		
	  		set_up_logging_variables

	  		until @last_page
	  			page_count += 1
	  			process_next_batch_of_authorship_data(page_count, page_size, poll_since)
	  			update_message = "#{@total_running_count} records were processed in #{distance_of_time_in_words_to_now(@start_time)}"
	  			puts update_message
	  			@cap_authorship_logger.info update_message
	  			if page_count === 1 then break end
	  		end
	
			puts "authors to harvest: " + @new_or_changed_authors_to_harvest_queue.to_s
			ScienceWireHarvester.new.harvest_pubs_for_author_ids(@new_or_changed_authors_to_harvest_queue)

	      	write_stats_from_logging_variables_to_log

	      	puts "#{page_count} pages with #{page_size} records per page were processed in distance_of_time_in_words_to_now(@start_time)"
	  		puts "#{@new_author_count} authors were created."

	    rescue => e
	    	NotificationManager.handle_authorship_pull_error(e, "Authorship import failed - #{DateTime.now}" )      	
	    end
  	end

  	def process_next_batch_of_authorship_data(page_count, page_size, since)
  		json_response = @cap_http_client.get_batch_from_cap_api(page_count, page_size, since)
  		 
		if json_response["count"].blank? || json_response["lastPage"].nil?
			raise "unexpected json in cap_authors_poller#process_next_batch_of_authorship_data, first 500 chars: #{json_response}"		
		elsif json_response["values"]
	  		json_response["values"].each do | record |
	  			begin
		  			@total_running_count += 1

		  			cap_profile_id = record["profile"]["profileId"]
		  			sunetid = record["profile"]["uid"]
		  			california_physician_license = record["profile"]["californiaPhysicianLicense"]
		  			university_id = record["profile"]["universityId"]

		  			active = record["active"]
		  			import_enabled = record["importEnabled"]
		  			import_settings_exist = record["importSettings"] && record["importSettings"].any?

		  			emails_for_harvest = []

		  			new_author_attributes = {
		  				cap_profile_id: cap_profile_id,
		  				active_in_cap: active,
		  				cap_import_enabled: import_enabled
		  			}
		  			
					unless university_id.blank? then new_author_attributes[:university_id] = university_id  end
					unless sunetid.blank? then new_author_attributes[:sunetid] = sunetid  end
					unless california_physician_license.blank? then new_author_attributes[:california_physician_license] = california_physician_license  end

		  			if active && import_enabled && import_settings_exist
		  				record["importSettings"].each do |import_settings|
			  				if ! import_settings["email"].blank?				
			  					 emails_for_harvest << import_settings["email"]
			  				end
			  				unless import_settings["firstName"].blank? then new_author_attributes[:cap_first_name] = import_settings["firstName"]  end
							unless import_settings["lastName"].blank? then new_author_attributes[:cap_last_name] = import_settings["lastName"]  end
		  				end
		  			else
		  				@no_import_settings_count += 1
		  			end
			
		  			if emails_for_harvest.blank? then @no_email_in_import_settings += 1 end
					active ? @active_true_count +=1 : @active_false_count +=1
					import_enabled ? @import_enabled_count += 1 : @import_disabled_count += 1 

					new_author_attributes[:emails_for_harvest] = emails_for_harvest.empty? ? nil : emails_for_harvest.join(',')
			
					author = Author.where(cap_profile_id: cap_profile_id).first
					if author
						author.update_attributes(new_author_attributes)
						author.contributions.each { |contrib | contrib.update_attribute(:cap_profile_id, author.cap_profile_id)}
						@authors_updated_count += 1
					else
						author = Author.create(new_author_attributes)
						@new_author_count += 1
					end 
					@new_or_changed_authors_to_harvest_queue << author.id
					if record["authorship"]
	  					record["authorship"].each do |authorship|
	  						contrib = Contribution.where(author_id: author.id, publication_id: record["sulPublicationId"]).first_or_create
	  						update_hash = {featured: record["featured"], status: record["status"], visibility: record["visibility"]}
	  						contrib.update_attributes(update_hash)
	  					end
		  			end
				rescue => e 
					NotificationManager.handle_authorship_pull_error(e, "Authorship import failed for incoming record containing: #{json_response.to_s} - #{DateTime.now}")
				end			
	  		end		
		end	
		@last_page = json_response["lastPage"]
  	end

  	def set_up_logging_variables
  		@start_time = Time.now
  		@total_running_count = 0
  		@new_author_count = 0
  		@authors_updated_count = 0
  		@no_import_settings_count = 0
  		@no_email_in_import_settings = 0
  		@active_true_count = 0
  		@active_false_count = 0
  		@no_active_count = 0
  		@import_enabled_count = 0
  		@import_disabled_count = 0
	 end

  	def write_stats_from_logging_variables_to_log
  		@cap_authorship_logger.info "Finished authorship import - #{DateTime.now}" 
      	@cap_authorship_logger.info "#{@total_running_count} records were processed in " + distance_of_time_in_words_to_now(@start_time)
      	@cap_authorship_logger.info "#{@new_author_count} authors were created."
      	@cap_authorship_logger.info "#{@no_import_settings_count} records with no import settings."
      	@cap_authorship_logger.info "#{@no_email_in_import_settings} records with no email in import settings."
      	@cap_authorship_logger.info "#{@active_true_count} records with 'active' true."
      	@cap_authorship_logger.info "#{@active_false_count} records with 'active' false."
      	@cap_authorship_logger.info "#{@no_active_count} records with no 'active' field in profile."
      	@cap_authorship_logger.info "#{@authors_updated_count} authors were updated."
      	@cap_authorship_logger.info "#{@import_enabled_count} authors had import enabled."
      	@cap_authorship_logger.info "#{@import_disabled_count} authors had import disabled."
  	end

 end
