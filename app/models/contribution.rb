class Contribution < ActiveRecord::Base
  attr_accessible :status, :visibility, :featured, :author_id, :publication_id, :cap_profile_id
  belongs_to :publication
  belongs_to :author
 # has_one :publication_identifier, :foreign_key => "publication_id"
  has_one :publication_identifier, 
          :class_name => "PublicationIdentifier",
          :foreign_key => "publication_id",
          :primary_key => "publication_id",
          :conditions => "publication_identifiers.identifier_type = 'PublicationItemId'"
  #has_one :population_membership, :foreign_key => "author_id"

  def self.valid_authorship_hash?(authorship_hash)
  	#puts authorship_hash.to_s
    authorship_hash.all? do |contrib|
          authors_valid?(contrib) && all_fields_present?(contrib)
    end
 end

 def self.authors_valid?(contrib)
 	if ! contrib[:sul_author_id].blank? 
    	Author.exists?(contrib[:sul_author_id])
  	elsif ! contrib[:cap_profile_id].blank?
    	Author.exists?(cap_profile_id: contrib[:cap_profile_id])
  	else
  		# there must be at least one valid author id
    	false
  	end
 end

 def self.all_fields_present?(contrib)
 	 ! (contrib[:visibility].blank? || contrib[:featured].nil? || contrib[:status].blank?)
 end

end
