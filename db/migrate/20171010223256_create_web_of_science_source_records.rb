class CreateWebOfScienceSourceRecords < ActiveRecord::Migration
  def change
    create_table :web_of_science_source_records do |t|
      t.boolean :active
      t.string :database
      t.text :source_data
      t.string :source_fingerprint
      t.string :uid

      t.timestamps null: false
    end
    add_index :web_of_science_source_records, :uid, name: 'web_of_science_uid_index'
  end
end
