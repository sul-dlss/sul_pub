class CreatePopulationMemberships < ActiveRecord::Migration
  def change
    create_table :population_memberships do |t|
      t.integer :author_id
      t.integer :cap_profile_id
      t.string :population_name

      t.timestamps
    end
  end
end
