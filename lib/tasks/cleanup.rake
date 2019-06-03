require 'csv'

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
  #  in the 'new' state with visibility 'private' between the dates specified, and then remove the publications
  #  too if they are no longer connected to any one else's profile and match the specified provenance.
  #  Should be rare in usage and then followed up with another harvest for this profile using:
  #  RAILS_ENV=production bundle exec rake harvest:author[123]

  # RAILS_ENV=production bundle exec rake cleanup:remove_new_contributions[123,'April 25 2018','May 1 2018','pubmed'] # will remove all contributions in the 'new' state for the given cap_profile_id, then remove any publications that have no contributions anymore
  task :remove_new_contributions, [:cap_profile_id, :start_timeframe, :end_timeframe, :provenance] => :environment do |_t, args|
    PaperTrail.enabled = false
    log_file = 'log/cleanup_remove_new_contributions.log'

    cap_profile_id = args[:cap_profile_id]
    start_timeframe = args[:start_timeframe]
    end_timeframe = args[:end_timeframe]
    provenance = args[:provenance]

    raise 'Missing cap_profile_id' unless cap_profile_id
    raise 'Missing start_timeframe' unless start_timeframe
    raise 'Missing end_timeframe' unless end_timeframe
    raise 'Missing provenance' unless provenance

    author = Author.find_by_cap_profile_id(cap_profile_id)
    raise 'Author not found' unless author

    start_date = Time.parse(start_timeframe) # start date to go back to look for new contributions (when we started WoS harvesting)
    end_date = Time.parse(end_timeframe) # end date to go back to look for new contributions (when we stopped harvesting with first initial)

    pub_ids_worked_on_dump_file = "log/pubids_for_#{cap_profile_id}_#{provenance}.dump"

    contributions = author.contributions.where('status = ? and visibility = ? and created_at > ? and created_at < ?', 'new', 'private', start_date, end_date)

    total = contributions.size
    deleted_pubs = 0
    deleted_contrib = 0
    updated = 0
    pub_ids = []

    puts "Author cap_profile_id: #{cap_profile_id}; name: #{author.first_name} #{author.last_name}; dates: #{start_date} to #{end_date}; provenance: #{provenance}"
    puts "This task will remove any of the #{total} contributions with provenance #{provenance}. Are you sure you want to proceed? (y/n)"
    input = STDIN.gets.strip.downcase
    raise 'aborting' unless input == 'y'

    CSV.open(log_file, "a") do |csv|
      puts "removing contributions with publication provenance #{provenance}..."
      contributions.each_with_index do |contribution, i|
        next unless contribution.publication.pub_hash[:provenance] == provenance
        puts "#{i + 1} of #{total}: Deleted contribution id #{contribution.id} for publication id #{contribution.publication_id}"
        deleted_contrib += 1
        pub_ids << contribution.publication_id
        contribution.destroy
      end

      File.open(pub_ids_worked_on_dump_file, 'w') { |f| f.write(YAML.dump(pub_ids)) }
      total_pub_ids = pub_ids.count
      puts 'updating publications...'
      # either rebuild the publications that were removed from the profile, or delete them if they have no contributions left
      pub_ids.each_with_index do |pub_id, i|
        pub = Publication.find(pub_id)
        if pub.contributions.empty? # no contributions left, destroy this publication and associated source record if they exist
          puts "#{i + 1} of #{total_pub_ids}: Deleted publication id #{pub_id}"
          deleted_pubs += 1
          csv << [pub_id]
          pub.destroy!
        else # still has contributions, let's rebuid the pub hash to update the authorship to reflect this author being removed
          puts "#{i + 1} of #{total_pub_ids}: Updated authorship for publication #{pub_id}"
          updated += 1
          pub.rebuild_authorship
          pub.save
        end
      end
    end
    # close csv
    puts ''
    puts "Considered #{total} contributions; deleted #{deleted_contrib} contributions; deleted #{deleted_pubs} publications, updated #{updated} publications."
  end

  desc 'Reset updated_at timestamp for publications based on last contribution change'
  # Use case: bad code resulted in unncessarily saving publications when no contributions actually changed.
  #  This results in the updated_at timestamp on the publication being set and lots of results being returned
  #  in the API.  We can adjust the updated_at timestamp by looking at the last associated contribution timestamp.
  #  Should be rare in usage and is really meant to remedy bad data from this issue: https://github.com/sul-dlss/sul_pub/issues/1071
  # RAILS_ENV=production bundle exec rake cleanup:fix_publication_timestamp['April 25 2019'] # will adjust any publication updated_timestamps after this date to the last contribution timestamp for that publication
  task :fix_publication_timestamp, [:start_timeframe] => :environment do |_t, args|
    PaperTrail.enabled = false
    start_timeframe = args[:start_timeframe]
    raise 'Missing start_timeframe' unless start_timeframe
    start_date = Time.parse(start_timeframe) # start date to go back to look
    total = Publication.where('updated_at > ?', start_date).count
    updated_pubs = 0
    i = 0
    puts "This task will update any of the updated_at timestamps for the #{total} publications after #{start_date} to match the last timestamp for any associated contributions for those publications.  Are you sure you want to proceed? (y/n)"
    input = STDIN.gets.strip.downcase
    raise 'aborting' unless input == 'y'
    Publication.select(:id, :updated_at).where('updated_at > ?', start_date).find_each do |pub|
      i += 1
      next if pub.contributions.empty? # skip any publications without contributions
      last_contribution_date = pub.contributions.order('updated_at desc').first.updated_at
      puts "#{i} of #{total} : pub.id #{pub.id} : pub.updated_at #{pub.updated_at} : lastest_contribution_updated_at #{last_contribution_date}"
      if last_contribution_date < pub.updated_at
        updated_pubs += 1
        pub.update_column(:updated_at, last_contribution_date)
      end
    end
    puts ''
    puts "Considered #{total} publications; updated #{updated_pubs} publication timestamps."
  end
end
