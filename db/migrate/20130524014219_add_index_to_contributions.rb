class AddIndexToContributions < ActiveRecord::Migration
  def change
  	add_index :contributions, :cap_profile_id
  	add_index :contributions, :publication_id
  	add_index :contributions, :author_id
  	add_index :contributions, [:publication_id, :author_id]
  end
end
