class AddIndexToAuthorsCapVisibility < ActiveRecord::Migration[6.0]
  def change
    add_index :authors, :cap_visibility
  end
end
