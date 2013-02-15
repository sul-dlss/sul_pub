class Contribution < ActiveRecord::Base
  attr_accessible :confirmed_status, :highlight_ind, :author_id, :publication_id, :cap_profile_id
  belongs_to :publication
  belongs_to :author
  has_one :population_membership, :foreign_key => "author_id"
end
