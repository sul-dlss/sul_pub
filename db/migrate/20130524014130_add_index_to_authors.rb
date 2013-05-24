class AddIndexToAuthors < ActiveRecord::Migration
  def change
  	add_index :authors, :cap_profile_id
  	add_index :authors, :sunetid
  	add_index :authors, :active_in_cap
end
  
end
