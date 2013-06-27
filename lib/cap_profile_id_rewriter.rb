require 'dotiw'
class CapProfileIdRewriter
	include ActionView::Helpers::DateHelper

	def rewrite_cap_profile_ids_from_feed
  		
  		begin
  			@cap_http_client = CapHttpClient.new 
			
			@cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_profile_id_rewrite.log'))
	  		@cap_authorship_logger.info "Started cap profile id rewrite  - #{DateTime.now}" 
	  		@page_count = 0
	  		@last_page = false
	  		
	  		initialize_counts_for_logging
	  		until @last_page
	  			@page_count += 1
	  			process_next_batch_of_authorship_data(@page_count, 1000)
	  			puts (@total_running_count).to_s + " in " + distance_of_time_in_words_to_now(@start_time, include_seconds = true)
	  			@cap_authorship_logger.info @total_running_count.to_s + " records were processed in " + distance_of_time_in_words_to_now(@start_time)

	  			#if page_count === 1 then break end
	  		end
	  		write_counts_to_log
	  		
	    rescue => e
	      	@cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_profile_id_rewrite.log'))
	      	@cap_authorship_logger.error "cap profile id rewrite import failed - #{DateTime.now}" 
	      	@cap_authorship_logger.error e.message
	      	@cap_authorship_logger.error e.backtrace
	      	puts e.message
	      	puts e.backtrace
	    end
  	end

  	def initialize_counts_for_logging
  		@start_time = Time.now
  		@total_running_count = 0
  		@new_author_count = 0
  		@authors_updated_count = 0
  		@no_import_settings_count = 0
  		@no_email_in_import_settings = 0
  		@active_true_count = 0
  		@active_false_count = 0
  		@no_profile_email_count = 
  		@no_active_count = 0
  		@import_enabled_count = 0
  		@import_disabled_count = 0
  	end

  	def write_counts_to_log
      	@cap_authorship_logger.info "Finished cap profile id rewrite - #{DateTime.now}" 
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
      	puts @new_author_count.to_s + " authors were created."
  		puts @page_count.to_s + " pages of 1000 records were processed in " + distance_of_time_in_words_to_now(@start_time)
  		puts @total_running_count.to_s + " total records were processed in " + distance_of_time_in_words_to_now(@start_time)
  	end

  	def process_next_batch_of_authorship_data(page_count, page_size)
  		json_response = @cap_http_client.get_batch_from_cap_api(page_count, page_size, nil)
  		 
		
		if json_response["values"].blank?
			puts "unexpected json: " + json_response.to_s
			@cap_authorship_logger.info "Authorship import ended unexpectedly. Returned json: "
			@cap_authorship_logger.info json_response.to_s		
			# TODO send an email here.
			raise			
		else
	  		json_response["values"].each do | record |
	  			@total_running_count += 1

	  			cap_profile_id = record["profile"]["profileId"]
	  			sunetid = record["profile"]["uid"]
	  			california_physician_license = record["profile"]["californiaPhysicianLicense"]
	  			university_id = record["profile"]["universityId"]

	  			active = record["active"]
	  			import_enabled = record["importEnabled"]
	  			import_settings_exist = record["importSettings"] 

	  			emails_for_harvest = []

	  			new_author_attributes = {
	  				cap_profile_id: cap_profile_id,
	  				active_in_cap: active,
	  				cap_import_enabled: import_enabled
	  			}
	  			
				unless university_id.blank? then new_author_attributes[:university_id] = university_id  end
				unless sunetid.blank? then new_author_attributes[:sunetid] = sunetid  end
				unless california_physician_license.blank? then new_author_attributes[:california_physician_license] = california_physician_license  end

	  			if import_settings_exist
	  				record["importSettings"].each do |import_settings|
		  				if ! import_settings["email"].blank?				
		  					 emails_for_harvest << import_settings["email"]
		  				end
		  				unless import_settings["firstName"].blank? then new_author_attributes[:cap_first_name] = import_settings["firstName"]  end
		  				unless import_settings["middleName"].blank? then new_author_attributes[:cap_middle_name] = import_settings["middleName"]  end
						unless import_settings["lastName"].blank? then new_author_attributes[:cap_last_name] = import_settings["lastName"]  end
	  				end
	  			else
	  				@no_import_settings_count += 1
	  			end
	  						
	  			if emails_for_harvest.blank? then @no_email_in_import_settings += 1 end
				active ? @active_true_count +=1 : @active_false_count +=1
				import_enabled ? @import_enabled_count +=1 : @import_disabled_count += 1 

				new_author_attributes[:emails_for_harvest] = emails_for_harvest.empty? ? nil : emails_for_harvest.join(',')
		
	  			if !sunetid.blank? 
	  				author = Author.where(sunetid: sunetid).first 
	  			end
	  			if author.nil? && !university_id.blank?
	  				author = Author.where(university_id: university_id).first
	  			end
	  			if author.nil? && !california_physician_license.blank?
	  				author = Author.where(california_physician_license: california_physician_license).first
	  			end	
				if author
					author.update_attributes(new_author_attributes)
					author.contributions.each { |contrib | contrib.update_attribute(:cap_profile_id, author.cap_profile_id)}
					@authors_updated_count += 1
				else
					author = Author.create(new_author_attributes)
					@new_author_count += 1
				end 			
	  		end
  			@last_page = json_response["lastPage"]
		end	
  	end




end