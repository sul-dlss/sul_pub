require 'dotiw'
require 'activerecord-import'
require "net/http"
require "json"
#require "always_verify_ssl_certificates"

namespace :cap do

	desc "poll cap for authorship information"
    task :poll => :environment do
		get_authorship_data
		CapAuthorshipMailer.welcome_email("some test text").deliver
  	end

  	def get_authorship_data
  		include ActionView::Helpers::DateHelper
		start_time = Time.now
		@cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
  		@cap_authorship_logger.info "Started authorship import - #{DateTime.now}" 
  		page_count = 0
  		@last_page = false
  		@total_running_count = 0
  		@no_author_count = 0
  		@authors_updated_count = 0
  		@no_import_settings_count = 0
  		@no_email_in_import_settings = 0
  		@active_true_count = 0
  		@active_false_count = 0
  		@no_profile_email_count = 0
  		@no_active_count = 0

  		until @last_page
  			page_count += 1
  			process_next_batch_of_authorship_data(page_count, 1000)
  			puts (@total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
  			@cap_authorship_logger.info @total_running_count.to_s + " records were processed in " + distance_of_time_in_words_to_now(start_time)

  			#if page_count === 1 then break end
  		end
  		puts page_count.to_s + " pages of 1000 records were processed in " + distance_of_time_in_words_to_now(start_time)
  		puts @total_running_count.to_s + " total records were processed in " + distance_of_time_in_words_to_now(start_time)
  		puts @no_author_count.to_s + " authors were created."
      	@cap_authorship_logger.info "Finished authorship import - #{DateTime.now}" 
      	@cap_authorship_logger.info "#{@total_running_count} records were processed in " + distance_of_time_in_words_to_now(start_time)
      	@cap_authorship_logger.info "#{@no_author_count} authors were created."
      	@cap_authorship_logger.info "#{@no_import_settings_count} records with no import settings."
      	@cap_authorship_logger.info "#{@no_email_in_import_settings} records with no email in import settings."
      	@cap_authorship_logger.info "#{@active_true_count} records with 'active' true."
      	@cap_authorship_logger.info "#{@active_false_count} records with 'active' false."
      	@cap_authorship_logger.info "#{@no_profile_email_count} records with no email in profile."
      	@cap_authorship_logger.info "#{@no_active_count} records with no 'active' field in profile."
      	@cap_authorship_logger.info "#{@authors_updated_count} authors were updated."
  	end

  
  	def process_next_batch_of_authorship_data(page_count, page_size)
  		begin
  			timeout_retries ||= 3
  			timeout_period ||= 500
	  		auth = YAML.load(File.open(Rails.root.join('config', 'cap_auth.yaml')))
			#AlwaysVerifySSLCertificates.ca_file = '/opt/local/share/curl/curl-ca-bundle.crt'
			http = Net::HTTP.new(auth[:authorship_api_uri_qa], auth[:authorship_api_port])	
			http.read_timeout = timeout_period
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_PEER
			#http.ca_file = '/opt/local/share/curl/curl-ca-bundle.crt'
		#	http.verify_mode = OpenSSL::SSL::VERIFY_PEER
			http.ssl_version = :SSLv3
			request = Net::HTTP::Get.new(auth[:authorship_api_path_qa] + "?p=" + page_count.to_s + "&ps=" + page_size.to_s)
			#puts "bearer " + auth[:token].to_s
			token = auth[:access_token]
			
			3.times do
				request["Authorization"] = "bearer " + token
				http.start
				response = http.request(request)

				if response.class == Net::HTTPUnauthorized 
					http.finish
					token = get_new_token
				elsif response.class == Net::HTTPInternalServerError
					http.finish
					puts "a server error: "
					puts response.body.to_s
					@last_page = true
					break
				else
					response_body = response.body
					the_response_as_hash = JSON.parse(response_body)
					process_batch(the_response_as_hash)
					http.finish
					break
				end
			end
		rescue Timeout::Error => te	
			timeout_retries -= 1
			if timeout_retries > 0
				# increase timeout
				timeout_period =+ 500
				retry
			else
				@cap_authorship_logger.info "Timeout error on authorship call - #{DateTime.now}" 
				@cap_authorship_logger.info "Error: #{te.backtrace}"
			end
		rescue => e
			puts e.message
			puts e.backtrace
			@cap_authorship_logger.info "Error: #{e.backtrace}"
		end
		@last_page
  	end

  	def process_batch(json_response)
  		#puts "in the process_batch"
  			if json_response["values"].blank?
  				puts "unexpected json: " + json_response.to_s
  				@cap_authorship_logger.info "Authorship import ended unexpectedly. Returned json: "
  				@cap_authorship_logger.info json_response.to_s		
  				# we return as though last page since we can't check.
  				# TODO send an email here.
  				@last_page = true
  			else
		  		json_response["values"].each do | record |
		  			@total_running_count += 1

		  			cap_profile_id = record["profile"]["profileId"]
		  			new_author_attributes = {cap_profile_id: cap_profile_id}

		  			active = record["active"]
		  			import_enabled = record["importEnabled"]
		  			  			
		  			sunetid = record["profile"]["uid"]
		  			california_physician_license = record["profile"]["californiaPhysicianLicense"]
		  			university_id = record["profile"]["universityId"]
		  			email = false

		  			if active && import_enabled && record["importSettings"] && record["importSettings"].any?
		  				record["importSettings"].each do |import_settings|
			  				if import_settings["email"].blank?
			  					@no_email_in_import_settings
			  				else
			  					email = true
			  					new_author_attributes[:email] = import_settings["email"]
			  				end
			  				unless import_settings["firstName"].blank? then new_author_attributes[:cap_first_name] = import_settings["firstName"]  end
	  						unless import_settings["lastName"].blank? then new_author_attributes[:cap_last_name] = import_settings["lastName"]  end
		  				end
		  			else
		  				@no_import_settings_count += 1
		  			end
		  						
					active ? @active_true_count +=1 : @active_false_count +=1
					new_author_attributes[:active_in_cap] = active  

					import_enabled ? @import_enabled_count +=1 : @import_disabled_count += 1 
					new_author_attributes[:cap_import_enabled] = import_enabled 
					

  					unless university_id.blank? then new_author_attributes[:university_id] = university_id  end
  					unless sunetid.blank? then new_author_attributes[:sunetid] = sunetid  end
  					unless california_physician_license.blank? then new_author_attributes[:california_physician_license] = california_physician_license  end
  					
  		
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
	  					#@cap_authorship_logger.info "updated author: " + author.id.to_s
	  					author.update_attributes(new_author_attributes)
	  					author.contributions.each { |contrib | contrib.update_attribute(:cap_profile_id, author.cap_profile_id)}
	  					@authors_updated_count += 1
	  				else
	  					author = Author.create(new_author_attributes)
	  				#	@cap_authorship_logger.info "author created: " + author.id.to_s
	  					@no_author_count += 1

	  				end 			
		  		end
		  		@last_page = json_response["lastPage"]
  			end	
  	end

  	def get_new_token
  		puts "in the get_new_token"
  		auth = YAML.load(File.open(Rails.root.join('config', 'cap_auth.yaml')))
  		http = Net::HTTP.new(auth[:get_token_uri], auth[:get_token_port])
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_PEER
		http.ssl_version = :SSLv3
		request = Net::HTTP::Post.new(auth[:get_token_path])
		request.basic_auth(auth[:get_token_user], auth[:get_token_pass])
		request.set_form_data({"grant_type" => "client_credentials"})	
		http.start	   
		token = JSON.parse(http.request(request).body)["access_token"]
		auth[:access_token] = token.to_s
		#puts "the token: " + token.to_s
		http.finish
		File.open(Rails.root.join('config', 'cap_auth.yaml'), 'w') {|f| YAML.dump(auth, f)}
		#puts token.to_s
		token.to_s
  	end

end
