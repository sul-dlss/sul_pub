class Publication < ActiveRecord::Base
  attr_accessible :active, :human_readable_title, :json, :lock_version, :publication_id, :same_as_publication_id, :xml
end
