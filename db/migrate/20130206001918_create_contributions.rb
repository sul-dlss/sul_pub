class CreateContributions < ActiveRecord::Migration[4.2]
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

    add_index :contributions, :cap_profile_id
    add_index :contributions, :publication_id
    add_index :contributions, :author_id
    add_index :contributions, [:publication_id, :author_id]
  end
end
