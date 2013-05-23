class Author < ActiveRecord::Base
  attr_accessible :cap_profile_id, :sunetid, :university_id, :active_in_cap, :email, :cap_first_name, :cap_last_name, :cap_middle_name, :official_first_name, :official_last_name, :official_middle_name, :preferred_first_name, :preferred_last_name, :preferred_middle_name 
  has_many :contributions, :dependent => :destroy
  has_many :publications, :through => :contributions do
  	def approved
  		where("contributions.status='approved'")
  	end
  end

  has_many  :approved_publications, :through => :contributions, 
          :class_name => "Publication", 
          :source => :publication,
          :conditions => ['contributions.status = ?','approved'] 
         

  #has_many :population_memberships, :dependent => :destroy
  #has_many :author_identifiers, :dependent => :destroy

 

end
