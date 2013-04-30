
require 'sciencewire'


namespace :sw do

  desc "harvest from sciencewire by email or sciencewire pub id"
  task :harvest => :environment do
    include ActionView::Helpers::DateHelper
    include Sciencewire
    harvest_author_pubs_from_sciencewire
  end

  

end
