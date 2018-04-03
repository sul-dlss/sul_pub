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
end
