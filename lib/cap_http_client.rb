require 'socket'
class CapHttpClient

  def initialize
    @main_auth = YAML.load(File.open(Rails.root.join('config', 'cap_auth.yaml')))
    if(Socket.gethostname =~ /^sulcap-prod/)
      @auth = @main_auth[:production]
    else
      @auth = @main_auth[:development]
    end
  end

	def get_new_token
		begin
  		http = Net::HTTP.new(auth[:get_token_uri], auth[:get_token_port])
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_PEER
			http.ssl_version = :SSLv3
			request = Net::HTTP::Post.new(@auth[:get_token_path])
			request.basic_auth(@auth[:get_token_user], @auth[:get_token_pass])
			request.set_form_data({"grant_type" => "client_credentials"})
			http.start
			token = JSON.parse(http.request(request).body)["access_token"]
			@auth[:access_token] = token.to_s
			#puts "the token: " + token.to_s
			http.finish
			File.open(Rails.root.join('config', 'cap_auth.yaml'), 'w') {|f| YAML.dump(@main_auth, f)}
			#puts token.to_s
			token.to_s
		rescue Timeout::Error => te
			timeout_retries -= 1
			if timeout_retries > 0
				# increase timeout
				timeout_period =+ 500
				retry
			else
				NotificationManager.handle_authorship_pull_error(te, "Timeout error on call to retrieve token for cap authorship feed - #{DateTime.now}" )
				raise
			end
		rescue => e
			NotificationManager.handle_authorship_pull_error(e, "Problem with http call to cap authorship api")
			raise
		end

  	end

  	def get_batch_from_cap_api(page_count, page_size, since='')
  		#since = "2013-06-14T10:33:20.333-04:00"
  		json_response = {}
  		begin
  			timeout_retries ||= 3
  			timeout_period ||= 500
	  		auth = YAML.load(File.open(Rails.root.join('config', 'cap_auth.yaml')))
			#AlwaysVerifySSLCertificates.ca_file = '/opt/local/share/curl/curl-ca-bundle.crt'
			http = Net::HTTP.new(@auth[:authorship_api_uri], @auth[:authorship_api_port])
			http.read_timeout = timeout_period
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_PEER
			#http.ca_file = '/opt/local/share/curl/curl-ca-bundle.crt'
		#	http.verify_mode = OpenSSL::SSL::VERIFY_PEER
			http.ssl_version = :SSLv3
			request_path = "#{@auth[:authorship_api_path]}?p=#{page_count}&ps=#{page_size}"
			unless since.blank? then request_path << "&since=#{since}" end
			request = Net::HTTP::Get.new(request_path)
			#puts "bearer " + @auth[:token].to_s
			token = @auth[:access_token]

			3.times do
				request["Authorization"] = "bearer " + token
				http.start
				response = http.request(request)

				if response.class == Net::HTTPUnauthorized
					http.finish
					token = get_new_token
				elsif response.class == Net::HTTPInternalServerError
					http.finish
					response_body = response.body
					raise "Server error on authorship call - #{DateTime.now} - message from server: #{response_body}"
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
				NotificationManager.handle_authorship_pull_error(te, "Timeout error on authorship call - #{DateTime.now}" )
				raise
			end
		rescue => e
			NotificationManager.handle_authorship_pull_error(e, "Problem with http call to cap authorship api")
			raise
		end
		json_response
  	end
end