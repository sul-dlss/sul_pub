class CreateSourceRecords < ActiveRecord::Migration
  def change
    create_table :source_records do |t|
      t.text :source_data
      t.integer :original_source_id
      t.integer :publication_id
      t.integer :lock_version
      t.string :human_readable_title
      t.integer :year
      t.string :source_name
      t.string :source_data_type
      t.boolean :is_active
      t.boolean :is_local_only
      t.timestamps
    end
  end
end
