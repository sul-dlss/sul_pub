class AuthorCapProfileIdUniqueness < ActiveRecord::Migration
  def change
    remove_index :authors, :cap_profile_id
    add_index :authors, :cap_profile_id, unique: true
  end
end
