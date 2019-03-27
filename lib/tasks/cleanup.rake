namespace :cleanup do
  desc 'Merge contributions FROM duped_cap_profile_id INTO primary_cap_profile_id'
  # Use case: a single author has two author rows with publications associated with each.
  # You want to merge one author into the author, carrying any existing publications but not duplicating them.
  # This happens when two profiles are created initially because CAP was not able to match the physician information
  # to the faculty information until after two profiles were created.  They "merged" them on the CAP side, but the
  # publications were not merged on the SUL-PUB side.  This manifests itself as unexpected behavior (missing pubs, etc.).
  #
  # This rake task takes in two cap_profile_ids and will merge all of the publications *from* DUPE_CAP_PROFILED_ID's profile *into* PRIMARY_CAP_PROFILE_ID's profile.
  # It will then deactivate DUPE_CAP_PROFILED_ID's profile (which should now have no publications associated with it) to prevent harvesting into it.

  # RAILS_ENV=production bundle exec rake cleanup:merge_profiles[123,456] # will merge all publications from cap_profile_id 456 into 123, without duplication
  task :merge_profiles, [:primary_cap_profile_id, :duped_cap_profile_id] => :environment do |_t, args|
    primary_cap_profile_id = args[:primary_cap_profile_id] # the profile you will be merging publications into
    duped_cap_profile_id = args[:duped_cap_profile_id] # the profile you will be merging publications out of and will be disabled

    raise "Missing primary_cap_profile_id" unless primary_cap_profile_id
    raise "Missing duped_cap_profile_id" unless duped_cap_profile_id

    primary_author = Author.find_by_cap_profile_id(primary_cap_profile_id)
    duped_author = Author.find_by_cap_profile_id(duped_cap_profile_id)

    puts "Primary Author cap_profile_id: #{primary_cap_profile_id}; name: #{primary_author.first_name} #{primary_author.last_name}"
    puts "Duplicate Author cap_profile_id: #{duped_cap_profile_id}; name: #{duped_author.first_name} #{duped_author.last_name}"
    puts "Merging duped author #{duped_author.cap_profile_id}'s #{duped_author.contributions.size} publications INTO primary author #{primary_author.cap_profile_id}'s #{primary_author.contributions.size} publications"
    puts

    primary_pub_ids = primary_author.publications.map(&:id)
    dupes_pub_ids = duped_author.publications.map(&:id)
    moved = 0
    removed = 0

    puts "There are currently #{(primary_pub_ids - dupes_pub_ids).size} publications in the primary profile that are not in the duped profile"
    puts "There are currently #{(dupes_pub_ids - primary_pub_ids).size} publications in the duped profile that are not in the primary profile --- these will be moved"

    duped_author.contributions.each do |contribution|
      if primary_pub_ids.include? contribution.publication_id # this publication already exists in the primary profile; remove it from the duped profile
        puts "Publication #{contribution.publication_id} already exists in the primary profile, removing this contribution from duped profile"
        removed += 1
        contribution.destroy
      else
        puts "Moving #{contribution.publication_id} to primary profile"
        moved += 1
        contribution.author_id = primary_author.id
        contribution.cap_profile_id = primary_author.cap_profile_id
        contribution.save
      end
    end

    puts "\n#{removed} publications removed from duped profile"
    puts "#{moved} publications moved to primary profile"
    puts "Publication IDs that were moved to primary profile: #{dupes_pub_ids - primary_pub_ids}"

    primary_author.reload
    duped_author.reload
    # rebuild all publications on the primary author profile
    primary_author.publications.each do |pub|
      pub.sync_publication_hash_and_db
      pub.save
    end

    puts "Authorship rebuilt in all publications associated with the primary profile"

    duped_author.cap_import_enabled = false
    duped_author.active_in_cap = false
    duped_author.save

    puts "Duped author set to inactive in cap\n"
    puts "Duped author #{duped_author.cap_profile_id} now has #{duped_author.contributions.size} publications (should be 0) and primary author #{primary_author.cap_profile_id} has #{primary_author.contributions.size} publications"
  end

  desc 'Remove all new contributions for a given cap_profile_id, and cleanup disconnected publications'
  # Use case: a researchers has many many new publications due to name ambiguities, because a harvest
  #  was run using last name, first initial and this user was determined to have many publications that
  #  do not actually belong to them.  This task will remove any publications associated with their profile
  #  in the 'new' state, and then remove the publications too if they are no longer connected to any one else's
  #  profile.  Should be rare in usage and then followed up with another harvest for this profile using:
  #  RAILS_ENV=production bundle exec rake wos:harvest_author[123]

  # RAILS_ENV=production bundle exec rake cleanup:remove_new_contributions[123] # will remove all contributions in the 'new' state for the given cap_profile_id, then remove any publications that have no contributions anymore
  task :remove_new_contributions, [:cap_profile_id] => :environment do |_t, args|
    cap_profile_id = args[:cap_profile_id]
    raise 'Missing cap_profile_id' unless cap_profile_id

    author = Author.find_by_cap_profile_id(cap_profile_id)
    raise 'Author not found' unless author

    start_timeframe = Time.parse('April 11, 2018') # start date to go back to look for new contributions (when we started WoS harvesting)
    end_timeframe = Time.parse('May 1, 2018') # end date to go back to look for new contributions (when we stopped harvesting with first initial)

    contributions = author.contributions.where(status: 'new').where('created_at > ?', start_timeframe).where('created_at < ?', end_timeframe)
    pub_ids = contributions.map(&:publication_id) # cache the ids of the contributions we are going to remove, so we can update them later

    total = contributions.size
    deleted = 0
    updated = 0

    puts "Author cap_profile_id: #{cap_profile_id}; name: #{author.first_name} #{author.last_name}"
    puts "This task will remove all #{total} of their new contributions. Are you sure you want to proceed? (y/n)"
    input = STDIN.gets.strip.downcase
    raise 'aborting' unless input == 'y'

    puts 'removing contributions...'
    contributions.each do |contribution|
      puts "...Deleted contribution id #{contribution.id}"
      contribution.destroy
    end

    puts 'updating publications...'
    # either rebuild the publications that were removed from the profile, or delete them if they have no contributions left
    pub_ids.each do |id|
      pub = Publication.find(id)
      if pub.contributions.empty? # no contributions left, delete this publication
        puts "...Deleted publication id #{id}"
        deleted += 1
        pub.delete!
      else # still has contributions, let's rebuid the pub hash to update the authorship to relfect this author being removed
        puts "...Updated authorship for publication id #{id}"
        updated += 1
        pub.sync_publication_hash_and_db
        pub.save
      end
    end

    puts "Removed #{total} contributions; deleted #{deleted} publications, updated #{updated} publications."
  end
end
