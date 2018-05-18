# simple script to batch harvest the most recently updated specified number of authors
# run with (probably in a screen)
# bundle exec rails runner -e production script/batch_wos_harvest.rb

limit = 1000 # limit to 1000 authors
options = { symbolicTimeSpan: '12week' } # go back 12 weeks in time
offset = 0 # increment offset to do a different batch (note that this will have overlaps if run far apart in time if you use updated_at as a sort order, as updated at times will change)
sort_order = 'updated_at desc' # do the people most recently updated
start_time = Time.zone.now
CSV.open(Rails.root.join('log', 'batch_wos_harvest.csv'), 'wb') do |csv|
  csv << ['cap_profile_id', 'name', 'new_publications']
  harvester = WebOfScience.harvester
  authors = Author.where(active_in_cap: true, cap_import_enabled: true).order(sort_order).limit(limit).offset(offset)
  total = authors.count
  puts "Harvesting of #{total} authors started at #{start_time}"
  authors.each_with_index do |author, i|
    puts "Harvesting cap_profile_id #{author.cap_profile_id} [#{i + 1} of #{total}]"
    harvester.process_author(author, options)
    new_pub_count = author.contributions.where(status: 'new').where('created_at >= ?', start_time).count
    csv << [author.cap_profile_id, "#{author.first_name} #{author.last_name}", new_pub_count]
  end
end
puts "Harvesting ended at #{Time.zone.now}"
puts "#{limit} authors were processed."
