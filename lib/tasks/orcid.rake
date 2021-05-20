# frozen_string_literal: true

namespace :orcid do
  desc 'Add works/publications to ORCID.org for all researchers/authors'
  task add_all_works: :environment do
    orcid_users = Mais.client.fetch_orcid_users
    logger = Logger.new(Rails.root.join('log/orcid_add_works.log'))
    count = Orcid::AddWorks.new(logger: logger).add_all(orcid_users)
    puts "Added #{count} works from #{orcid_users.size} ORCID users."
  end

  desc 'Add works/publications to ORCID.org for a single researchers/authors'
  task :add_author_works, [:sunetid] => :environment do |_t, args|
    # This approach for finding orcid_user can be replaced with https://github.com/sul-dlss/sul_pub/issues/1322
    orcid_user = Mais.client.fetch_orcid_users.find { |check_orcid_user| check_orcid_user.sunetid == args[:sunetid] }
    raise "Could not get ORCID.org access token for #{args[:sunetid]}" unless orcid_user

    logger = Logger.new(Rails.root.join('log/orcid_add_work.log'))
    count = Orcid::AddWorks.new(logger: logger).add_for_orcid_user(orcid_user)
    puts "Added #{count} works."
  end
end
