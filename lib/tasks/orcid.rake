# frozen_string_literal: true

namespace :orcid do
  desc 'Add works/publications to ORCID.org for all researchers/authors'
  task add_all_works: :environment do
    orcid_users = Mais.client.fetch_orcid_users
    logger = Logger.new(Rails.root.join('log/orcid_add_works.log'))
    count = Orcid::AddWorks.new(logger:).add_all(orcid_users)
    puts "Added #{count} works from #{orcid_users.size} ORCID users."
  end

  desc 'Add works/publications to ORCID.org for a single researchers/authors'
  task :add_author_works, [:sunetid] => :environment do |_t, args|
    orcid_user = Mais.client.fetch_orcid_user(sunetid: args[:sunetid])
    raise "Could not get ORCID.org access token for #{args[:sunetid]}" unless orcid_user

    logger = Logger.new(Rails.root.join('log/orcid_add_work.log'))
    count = Orcid::AddWorks.new(logger:).add_for_orcid_user(orcid_user)
    puts "Added #{count} works."
  end

  desc 'Harvest from ORCID.org for all authors'
  task harvest_authors: :environment do
    Orcid.harvester.harvest_all
  end

  desc 'Harvest from ORCID.org for a single author'
  task :harvest_author, [:sunetid] => :environment do |_t, args|
    author = Author.find_by(sunetid: args[:sunetid])
    raise "Could not find Author by sunetid: #{args[:sunetid]}." if author.nil?

    put_codes = Orcid.harvester.process_author(author)
    puts "Harvested #{put_codes.size} works/publications."
  end

  desc 'Deletes works/publications from ORCID.org for a single researcher/author'
  task :delete_author_works, [:sunetid] => :environment do |_t, args|
    orcid_user = Mais.client.fetch_orcid_user(sunetid: args[:sunetid])
    raise "Could not get ORCID.org access token for #{args[:sunetid]}" unless orcid_user

    logger = Logger.new(Rails.root.join('log/orcid_delete_works.log'))
    count = Orcid::DeleteWorks.new(logger:).delete_for_orcid_user(orcid_user)
    puts "Deleted #{count} works."
  end

  desc 'Deletes single work/publication from ORCID.org'
  task :delete_work, %i[sunetid contribution_id] => :environment do |_t, args|
    orcid_user = Mais.client.fetch_orcid_user(sunetid: args[:sunetid])
    raise "Could not get ORCID.org access token for #{args[:sunetid]}" unless orcid_user

    contribution = Contribution.find(args[:contribution_id].to_i)

    logger = Logger.new(Rails.root.join('log/orcid_delete_work.log'))
    if Orcid::DeleteWorks.new(logger:).delete_work(contribution, orcid_user)
      puts 'Deleted work.'
    else
      puts 'Did not delete work.'
    end
  end
end
