class PopulationMembership < ActiveRecord::Base
  attr_accessible :author_id, :population_name, :cap_profile_id
  has_many :authors
end
