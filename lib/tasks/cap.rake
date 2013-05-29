require 'dotiw'
require 'activerecord-import'
require "net/http"
require "json"

namespace :cap do

	desc "poll cap for authorship information"
    task :poll_authorship => :environment do
    	include ActionView::Helpers::DateHelper
		start_time = Time.now
		total_running_count = 0
		

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
  		auth = YAML.load(File.open(Rails.root.join('config', 'auth.yaml')))
		http = Net::HTTP.new(auth[:authorship_api_uri])	
		request = Net::HTTP::Get.new(auth[:authorship_api_path] + "?start=1&count=2")
		#puts "bearer " + auth[:token].to_s
		request["Authorization"] = "bearer " + auth[:access_token].to_s 
		http.start
		response = http.request(request)
		if response.code == 401 
			get_new_token
		end
			
		puts JSON.pretty_generate(JSON.parse(response.body))
		
		http.finish    
  	end

  	def get_new_token
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
  	end

end
