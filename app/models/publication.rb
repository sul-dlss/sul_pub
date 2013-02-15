class Publication < ActiveRecord::Base
  attr_accessible :active, :deleted, :human_readable_title, :json, :lock_version, :same_as_publication_id, :xml, :updated_at
  has_many :contributions
  has_many :people, :through => :contributions
  
end
