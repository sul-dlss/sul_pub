class CreateContributions < ActiveRecord::Migration
  def change
    create_table :contributions do |t|
      t.integer :author_id
      t.integer :cap_profile_id
      t.integer :publication_id
      t.string :status
      t.boolean :featured
      t.string :visibility

      t.timestamps
    end
  end
end
