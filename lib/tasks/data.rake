# frozen_string_literal: true

namespace :data do
  desc 'Backfile provenance into AR column for all records'
  # A new field was added to the publication table to allow for querying on publication provenance (already stored in pub_hash).
  # This task goes through all publications and adds the value to this field from the pub_hash
  # After this task completes, we can remove the `Publication#provenance` method
  # RAILS_ENV=production bundle exec rake cleanup:merge_profiles[123,456] # will merge all publications from cap_profile_id 456 into 123, without duplication
  # rubocop:disable Rails/SkipsModelValidations
  task add_provenance: :environment do |_t, _args|
    num_pubs = Publication.where(provenance: nil).count
    puts "Started at #{Time.zone.now}"
    puts "Found #{num_pubs} with missing provenance."
    Publication.where(provenance: nil).find_each.with_index do |pub, i|
      puts "#{i + 1} of #{num_pubs}"
      pub.update_column('provenance', pub.pub_hash[:provenance]) # skip callbacks and timestamp updates, just set the value
    end
    puts "Finished at #{Time.zone.now}"
  end
  # rubocop:enable Rails/SkipsModelValidations
end
