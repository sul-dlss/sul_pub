# simple script to batch harvest the most recently updated specified number of authors
# run with (probably in a screen)
# bundle exec rails runner -e production script/batch_wos_harvest.rb

limit = 1000 # limit to 1000 authors
options = { symbolicTimeSpan: '12week' } # go back 12 weeks in time
offset = 0 # increment offset to do a different batch (note that this will have overlaps if run far apart in time if you use updated_at as a sort order, as updated at times will change)
sort_order = 'updated_at desc' # do the people most recently updated

harvester = WebOfScience.harvester
authors = Author.where(active_in_cap: true, cap_import_enabled: true).order(sort_order).limit(limit).offset(offset)
total = authors.count
puts "Harvesting of #{total} authors started at #{Time.zone.now}"
authors.each_with_index do |author, i|
  puts "Harvesting cap_profile_id #{author.cap_profile_id} [#{i + 1} of #{total}]"
  harvester.process_author(author, options)
end
puts "Harvesting ended at #{Time.zone.now}"
