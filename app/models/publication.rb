class Publication < ActiveRecord::Base
  attr_accessible :active, :deleted, :human_readable_title, :year, :json, :lock_version, :same_as_publication_id, :xml, :updated_at
  has_many :contributions, :dependent => :destroy
  has_many :authors, :through => :contributions
  has_many :publication_identifiers, :dependent => :destroy
  has_many :publications_source_records
  has_many :source_records, :through => :publications_source_records
  has_many :population_membership, :foreign_key => "author_id"
  
end



