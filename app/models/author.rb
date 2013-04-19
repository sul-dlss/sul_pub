class Author < ActiveRecord::Base
  attr_accessible :ca_license_number, :cap_first_name, :cap_last_name, :cap_middle_name, :cap_url, :display_name, :official_first_name, :official_last_name, :official_middle_name, :preferred_first_name, :preferred_last_name, :preferred_middle_name, :cap_profile_id, :pubmed_first_initial, :pubmed_institution, :pubmed_last_name, :pubmed_middle_initial, :pubmed_other_institution, :shc_doctor_no, :sunetid, :university_id
  has_many :contributions, :dependent => :destroy
  has_many :publications, :through => :contributions do
  	def approved
  		where("contributions.confirmed_status='approved'")
  	end
  end


  has_many  :approved_publications, :through => :contributions, 
          :class_name => "Publication", 
          :source => :publication,
          :conditions => ['contributions.confirmed_status = ?','approved'] 
         


  has_many :population_memberships, :dependent => :destroy
  has_many :author_identifiers, :dependent => :destroy

  has_many :meeting_participations
  has_many :meetings, :through => :meeting_participations do
   def visible
     where("meeting_participations.visible = ?", true)
   end
  end
end
