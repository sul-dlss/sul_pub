# frozen_string_literal: true

namespace :mais do
  desc 'Fetch and print all ORCID users'
  task fetch: :environment do
    Mais.client.fetch_orcid_users.each do |orcid_user|
      puts "#{orcid_user.sunetid}: #{orcid_user.orcidid}"
    end
  end

  desc 'Fetch all ORCID users and update authors'
  task update_authors: :environment do
    orcid_users = Mais.client.fetch_orcid_users
    logger = Logger.new(Rails.root.join('log/mais_update_authors.log'))
    count = Mais::UpdateAuthorsOrcid.new(orcid_users, logger: logger).update
    puts "Updated #{count} author records from #{orcid_users.size} ORCID users."
  end
end
