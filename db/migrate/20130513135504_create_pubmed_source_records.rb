class CreatePubmedSourceRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :pubmed_source_records do |t|
      t.text :source_data
      t.integer :pmid
      t.integer :lock_version
      t.string :source_fingerprint
      t.boolean :is_active

      t.timestamps
    end
    add_index :pubmed_source_records, :pmid
  end
end
