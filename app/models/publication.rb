class Publication < ActiveRecord::Base
  attr_accessible :active, :human_readable_title, :json, :lock_version, :same_as_publication_id, :xml
  #has_many :publication_sources
  #has_many :sources through :publication_sources
end
