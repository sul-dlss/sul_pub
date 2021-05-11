require 'csv'
require 'dotiw'

# Considered obsolete Nov. 2017, unused since at least early 2016

namespace :cap_cutover do
  desc 'ingest authors from csv files'
  task :ingest_authors, [:file_location] => :environment do |_t, args|
    include ActionView::Helpers::DateHelper
    start_time = Time.zone.now
    total_running_count = 0

    CSV.foreach(args.file_location, headers: true, header_converters: :symbol) do |row|
      total_running_count += 1
      cap_profile_id = row[:profile_id]
      # author = Author.where(cap_profile_id: cap_profile_id).first_or_create
      #  if author.nil?
      Author.create(
        cap_profile_id: cap_profile_id,
        active_in_cap: row[:active_profile],
        sunetid: row[:sunetid],
        university_id: row[:university_id],
        email: row[:email_address],
        emails_for_harvest: row[:email_address],
        official_first_name: row[:official_first_name],
        official_last_name: row[:official_last_name],
        official_middle_name: row[:official_middle_name],
        cap_first_name: row[:cap_first_name],
        cap_last_name: row[:cap_last_name],
        cap_middle_name: row[:cap_middle_name],
        preferred_first_name: row[:preferred_first_name],
        preferred_last_name: row[:preferred_last_name],
        preferred_middle_name: row[:preferred_middle_name],
        california_physician_license: (row[:ca_license_number])
      )
      if total_running_count % 5000 == 0
        GC.start
        Rails.logger.debug "#{total_running_count} in #{distance_of_time_in_words_to_now(start_time, true)}"
      end
    end
  end

  desc 'update authors, utility to be used as needed for patches to records from csv file'
  task :update_authors, [:file_location] => :environment do |_t, args|
    include ActionView::Helpers::DateHelper
    start_time = Time.zone.now
    total_running_count = 0
    CSV.foreach(args.file_location, headers: true, header_converters: :symbol) do |row|
      total_running_count += 1
      cap_profile_id = row[:profile_id]
      Author.where(cap_profile_id: cap_profile_id).first.update(
        # active_in_cap: (row[:active_profile] == 'active'),
        california_physician_license: (row[:ca_license_number])
      )
      # if total_running_count%5000 == 0  then GC.start end
      Rails.logger.debug "#{total_running_count} in #{distance_of_time_in_words_to_now(start_time, true)}" if total_running_count % 5000 == 0
    end
    Rails.logger.info "#{total_running_count} in #{distance_of_time_in_words_to_now(start_time)}"
  end

  desc 'overwrite cap profile ids from CAP authorship feed - this is meant to be a very temporary, dangerous, and invasive procedure for creating qa machines for the School of Medicine testers.'
  task overwrite_profile_ids: :environment do
    if Rails.env.production?
      puts 'This is a PRODUCTION system - are you sure? (Y/N)'
      $stdout.flush
      input = $stdin.gets.chomp
      return unless input.upcase == 'Y'
    end
    Cap::ProfileIdRewriter.new.rewrite_cap_profile_ids_from_feed
  end
end
