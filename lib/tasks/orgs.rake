# frozen_string_literal: true

# Data is obtained using rialto-etl codebase:
# git clone https://github.com/sul-dlss-labs/rialto-etl.git
# cd rialto-etl
# rvm use 2.7 # rialto-etl still on ruby 2
# git checkout petucket-researcher-extract # this branch reduces the amount of data pulled for researchers to bare minimum
# bundle install
# exe/extract call StanfordOrganizations > organizations.json
# exe/extract call StanfordResearchers > researchers.ndj
#
# Go back to sul-pub codebase and grab data
# cd ../sul_pub
# mv ../rialto-etl/organizations.json .
# mv ../rialto-etl/researchers.ndj .
#
# Load data using rake tasks in sul-pub:
# bundle exec rake orgs:load_from_json['organizations.json']
# bundle exec rake orgs:load_researcher_affiliation['researchers.ndj']

# Uses awesome_nested_set: https://github.com/collectiveidea/awesome_nested_set
# Cheat sheet for nested_set API
# https://github.com/brennovich/cheat-ruby-sheets/blob/master/awesome_nested_set.md
#
# Find an author and their organizations
# author = Author.find_by(sunetid: 'kcasciot')
# author.organizations # see which organizations the author is part of
# author.author_organizations # see the role/affiliation (e.g. faculty/staff) for each organization
#
# Find an organization (e.g. a School)
# org = Organization.find_by(name: 'School of Earth, Energy and Environmental Sciences')
# org.ancestors # the school's parents (e.g. Stanford University)
# org.siblings # the school's siblings (e.g. other schools in the university)
# org.children # the school's immediate children (e.g. departments in the school)
# org.descendants # the school's children and all of it's children (e.g. departments plus anything below those departments)

# Find all of the researchers in a given higher level organization (e.g. a school, which has many departments)
# AuthorOrganization.where(organization_id: org.self_and_descendants.map(&:id)).map(&:author)

# Find all of the researchers associated with a single organization (e.g. a department)
# note: this will miss any authors not directly associated with the organization,
# e.g. faculty will be associated with a department, but not with the partent school directly in the data
# Organization.find_by(name: 'Earth System Science').authors

require 'json'

def load_organization(org, parent: nil)
  # each organization can have multiple org codes, create an entry for each
  org['orgCodes'].each do |org_code|
    # update or create as needed by searching for existing org_codes
    o = Organization.find_or_initialize_by(code: org_code)
    puts "Loading #{org_code} : #{org['name']}"
    o.update(name: org['name'], alias: org['alias'], org_type: org['type'])
    if parent
      parent_org = Organization.find_by(code: parent['orgCodes'].first)
      o.move_to_child_of(parent_org)
    end
    o.save
  end

  # recursive exit condition for no children in this organization
  return if org['children'].blank?

  # loop over organizational unit's children recursively
  org['children'].each { |child| load_organization(child, parent: org) }
end

namespace :orgs do
  desc 'Load organization data from JSON'
  # Load/update all organization data pulled from Profiles API into the database
  # bundle exec rake orgs:load_from_json['organizations.json']
  task :load_from_json, %i[input_file] => :environment do |_t, args|
    input_file = args[:input_file]
    raise 'input file missing or not specified' unless input_file && File.exist?(input_file)

    org_json = JSON.parse(File.read(input_file))
    load_organization(org_json) # defined above, we call this method recursively
  end

  desc 'Load researcher organization affiliation data from JSON'
  # Load/update all researcher organization affiliation data pulled from Profiles API into the database
  # bundle exec rake orgs:load_researcher_affiliation['researchers.ndj']
  task :load_researcher_affiliation, %i[input_file] => :environment do |_t, args|
    input_file = args[:input_file]
    raise 'input file missing or not specified' unless input_file && File.exist?(input_file)

    total_lines = 0
    total_authors_found = 0
    total_authors_orgs_added = 0

    File.readlines(input_file).each do |line|
      total_lines += 1
      researcher_json = JSON.parse(line)
      sunetid = researcher_json['uid']
      next if sunetid.blank?

      author = Author.find_by(sunetid: sunetid)
      next if author.blank?

      puts "loading #{sunetid}"
      total_authors_found += 1

      researcher_json['orgs']&.each do |org| # some researchers have no orgs, don't crash on nil
        total_authors_orgs_added += 1
        affiliation = org['affiliation']
        org_code = org['organization']['orgCode']
        puts ".... #{affiliation} : #{org_code}"
        organization = Organization.find_by(code: org_code)
        if organization && author.organizations.exclude?(organization)
          AuthorOrganization.create(author: author, organization: organization, affiliation: affiliation)
        end
      end
    end
    puts
    puts "Total lines in file: #{total_lines}. Total authors found: #{total_authors_found}. Total organization affiliations found: #{total_authors_orgs_added}"
  end
end
