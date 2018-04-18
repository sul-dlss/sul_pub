# simple script to batch harvest the most recently updated specified number of authors
# run with (probably in a screen)
# bundle exec rails runner -e production script/batch_wos_harvest.rb

options = { symbolicTimeSpan: '12week' } # go back 12 weeks in time
limit = 1000 # limit to 1000 authors
offset = 0 # increment offset to do a different batch (note that this will have overlaps if run far apart in time if you use updated_at as a sort order, as updated at times will change)
sort_order = 'updated_at desc' # do the people most recently updated

batch_size = 50 # in batches of 50
harvester = WebOfScience.harvester
Author.where(active_in_cap: true, cap_import_enabled: true).order(sort_order).limit(limit).offset(offset).find_in_batches(batch_size: batch_size).each do |batch|
  harvester.harvest(batch, options)
end
