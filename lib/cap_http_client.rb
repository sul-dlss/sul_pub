class CapHttpClient

	def get_new_token
  		begin
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
		rescue Timeout::Error => te	
			timeout_retries -= 1
			if timeout_retries > 0
				# increase timeout
				timeout_period =+ 500
				retry
			else
				@cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
				@cap_authorship_logger.info "Timeout error on token call - #{DateTime.now}" 
				@cap_authorship_logger.info "Error: #{te.backtrace}"
				raise
			end
		rescue => e
			@cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
			puts e.message
			puts e.backtrace
			@cap_authorship_logger.info "Error: #{e.backtrace}"
			raise
		end

  	end

  	def get_batch_from_cap_api(page_count, page_size, since)
  		#since = "2013-06-14T10:33:20.333-04:00"
  		json_response = {}
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
			request_path = "#{auth[:authorship_api_path_qa]}?p=#{page_count}&ps=#{page_size}"
			unless since.blank? then request_path << "&since=#{since}" end
			request = Net::HTTP::Get.new(request_path)
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
					response_body = response.body
					puts response_body.to_s
					@cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
					@cap_authorship_logger.info "Server error on authorship call - #{DateTime.now}" 
					@cap_authorship_logger.info "Message returned from server: #{response_body}"
					raise
				else
					response_body = response.body
					json_response = JSON.parse(response_body)
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
				@cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
				@cap_authorship_logger.info "Timeout error on authorship call - #{DateTime.now}" 
				@cap_authorship_logger.info "Error: #{te.message}"
				@cap_authorship_logger.info "#{te.backtrace}"
				raise
			end
		rescue => e
			@cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
			puts e.message
			puts e.backtrace
			@cap_authorship_logger.info "Error: #{e.message}"
			@cap_authorship_logger.info "#{e.backtrace}"
			raise
		end
		json_response
  	end
end