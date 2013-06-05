require 'dotiw'
require 'activerecord-import'
require "net/http"
require "json"
#require "always_verify_ssl_certificates"

namespace :cap do

	desc "poll cap for authorship information"
    task :poll_authorship => :environment do
    	
		#get_new_token
		get_authorship_data

		#auth = YAML.load(File.open('auth.yaml'))
		#auth={}
		#auth[:get_token_uri] = "***REMOVED***"
		#auth[:get_token_port] = 443
		#auth[:get_token_path] = "/oauth/token"
		#auth[:get_token_user] = "sul"
		#auth[:get_token_pass] = "***REMOVED***"
		#auth[:authorship_api_uri] = "irt-dev.stanford.edu"
		#auth[:authorship_api_path] = "/cap-api/api/cap/v1/authors"
  	end

  	def get_authorship_data
  		include ActionView::Helpers::DateHelper
		start_time = Time.now
		cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
  		cap_authorship_logger.info "Started authorship import " + DateTime.now.to_s
  		page_count = 0
  		last_page = false
  		@total_running_count = 0
  		until last_page
  			page_count += 1
  			last_page = process_next_batch_of_authorship_data(page_count, 1000)
  			puts (@total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)  
  			cap_authorship_logger.info @total_running_count.to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time)

  			#if page_count === 3 then break end
  		end
  		puts (page_count).to_s + "pages of 1000 were processed in " + distance_of_time_in_words_to_now(start_time)
  		puts (@total_running_count).to_s + "total records were processed in " + distance_of_time_in_words_to_now(start_time)
      	cap_authorship_logger.info "Finished authorship import." + DateTime.now.to_s
      	cap_authorship_logger.info @total_running_count.to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time)

  	end

  
  	def process_next_batch_of_authorship_data(page_count, page_size)
  		
  		auth = YAML.load(File.open(Rails.root.join('config', 'auth.yaml')))
		#AlwaysVerifySSLCertificates.ca_file = '/opt/local/share/curl/curl-ca-bundle.crt'
		http = Net::HTTP.new(auth[:authorship_api_uri_qa])	
		#http.use_ssl = true
		#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
		#http.ca_file = '/opt/local/share/curl/curl-ca-bundle.crt'
		#http.verify_mode = OpenSSL::SSL::VERIFY_PEER
		#http.ssl_version = :SSLv3
		request = Net::HTTP::Get.new(auth[:authorship_api_path_qa] + "?p=" + page_count.to_s + "&ps=" + page_size.to_s)
		#puts "bearer " + auth[:token].to_s
		token = auth[:access_token]
		@last_page = false
		3.times do
			#puts "in the 3 times loop"
			request["Authorization"] = "bearer " + token
			http.start
			response = http.request(request)
			#puts "got the response"
			if response.class == Net::HTTPUnauthorized 
				http.finish
				token = get_new_token
			else
				response_body = response.body
				#puts "the response: " + response_body.to_s
				the_response_as_hash = JSON.parse(response_body)
				#the_response = JSON.pretty_generate(JSON.parse(response.body))
				@last_page = process_batch(the_response_as_hash)
				break
			end
		end
		http.finish
		@last_page
  	end

  	def process_batch(json_response)
  		#puts "in the process_batch"
  		#puts json_response.to_s
  		json_response["values"].each do | record |
  			@total_running_count += 1
  			active = record["active"]
  			email = record["profile"]["email"]
  			sunetid = record["profile"]["uid"]
  			cap_profile_id = record["profile"]["profileId"]
  			author = Author.where(sunetid: sunetid).first
  			if author
  				author.update_attributes(cap_profile_id: cap_profile_id, email: email, active_in_cap: active)
  			end
  		end
  		return json_response["lastPage"]
  	end

  	def get_new_token
  		puts "in the get_new_token"
  		auth = YAML.load(File.open(Rails.root.join('config', 'auth.yaml')))
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
		puts "the token: " + token.to_s
		http.finish
		File.open(Rails.root.join('config', 'auth.yaml'), 'w') {|f| YAML.dump(auth, f)}
		puts token.to_s
		token.to_s
  	end

end
