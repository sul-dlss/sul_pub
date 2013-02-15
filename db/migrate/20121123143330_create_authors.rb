class CreateAuthors < ActiveRecord::Migration
  def change
    create_table :authors do |t|
      t.integer :cap_profile_id
      t.string :sunetid
      t.integer :university_id
      t.integer :shc_doctor_no
      t.string :ca_license_number
      t.string :cap_first_name
      t.string :cap_last_name
      t.string :cap_middle_name
      t.string :display_name
      t.string :official_first_name
      t.string :official_last_name
      t.string :official_middle_name
      t.string :preferred_first_name
      t.string :preferred_last_name
      t.string :preferred_middle_name
      t.string :pubmed_last_name
      t.string :pubmed_first_initial
      t.string :pubmed_middle_initial
      t.string :pubmed_institution
      t.string :pubmed_other_institution
      t.string :cap_url

      t.timestamps
    end
  end
end
