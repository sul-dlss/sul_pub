require 'sul_solr'

namespace :solr do

desc "reindex everything in solr"
  task :index => :environment do
    include SulSolr
    index_all_in_solr
  end

end