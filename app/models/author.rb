class Author < ActiveRecord::Base
  attr_accessible :cap_profile_id, :sunetid, :university_id, :california_physician_license, :active_in_cap, :cap_import_enabled, :emails_for_harvest, :email, :cap_first_name, :cap_last_name, :cap_middle_name, :official_first_name, :official_last_name, :official_middle_name, :preferred_first_name, :preferred_last_name, :preferred_middle_name 
  has_many :contributions, :dependent => :destroy
  has_many :publications, :through => :contributions do
  	def approved
  		where("contributions.status='approved'")
  	end
  end
  
  has_many  :approved_sw_ids, :through => :contributions, 
          :class_name => "PublicationIdentifier", 
          :source => :publication_identifier,
          :foreign_key => "publication_id",
          :primary_key => "publication_id",
          :conditions => "contributions.status = 'approved'"

  has_many  :approved_publications, :through => :contributions, 
          :class_name => "Publication", 
          :source => :publication,
          :conditions => ['contributions.status = ?','approved'] 
         

  #has_many :population_memberships, :dependent => :destroy
  #has_many :author_identifiers, :dependent => :destroy


end
