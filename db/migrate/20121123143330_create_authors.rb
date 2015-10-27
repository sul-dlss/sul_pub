class CreateAuthors < ActiveRecord::Migration
  def change
    create_table :authors do |t|
      t.integer :cap_profile_id
      t.boolean :active_in_cap
      t.string :sunetid
      t.integer :university_id
      t.string :email
      t.string :cap_first_name
      t.string :cap_last_name
      t.string :cap_middle_name
      t.string :official_first_name
      t.string :official_last_name
      t.string :official_middle_name
      t.string :preferred_first_name
      t.string :preferred_last_name
      t.string :preferred_middle_name

      t.timestamps
    end

    add_index :authors, :cap_profile_id
    add_index :authors, :sunetid
    add_index :authors, :active_in_cap
  end
end
