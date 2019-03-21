class CreateUserSubmittedSourceRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :user_submitted_source_records do |t|
      t.text :source_data
      t.integer :pmid
      t.integer :lock_version
      t.string :source_fingerprint
      t.string :title
      t.integer :year
      t.boolean :is_active
      t.integer :publication_id
      t.integer :author_id

      t.timestamps
    end
  end
end
