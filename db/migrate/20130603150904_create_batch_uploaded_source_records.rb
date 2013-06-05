class CreateBatchUploadedSourceRecords < ActiveRecord::Migration
  def change
    create_table :batch_uploaded_source_records do |t|
      t.string :sunet_id
      t.integer :author_id
      t.integer :cap_profile_id
      t.boolean :successful_import
      t.text :bibtex_source_data
      t.string :source_fingerprint
      t.boolean :is_active
      t.string :title
      t.integer :year
      t.string :batch_name
      t.text :error_message

      t.timestamps
    end

    add_index :batch_uploaded_source_records, :cap_profile_id
    add_index :batch_uploaded_source_records, :sunet_id
    add_index :batch_uploaded_source_records, :author_id
    add_index :batch_uploaded_source_records, :batch_name
    add_index :batch_uploaded_source_records, :title

  end
end
