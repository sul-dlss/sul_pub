
require 'sul_pub'

# puts "-u#{db_config['username']} -p#{db_config['password']} #{db_config['database']}"
namespace :sw do
  desc "harvest from sciencewire by email or sciencewire pub id"
  task :harvest => :environment do
    include ActionView::Helpers::DateHelper
    include SulPub
    harvest_author_pubs_from_sciencewire
  end
  task :index => :environment do
    include SulPub
    index_all_in_solr
  end
end
