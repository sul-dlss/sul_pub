require 'dotiw'
require 'activerecord-import'

namespace :cap do

	desc "poll cap for authorship information"
    task :poll => :environment do
    	include ActionView::Helpers::DateHelper
		start_time = Time.now
		total_running_count = 0
		
  	end

end
