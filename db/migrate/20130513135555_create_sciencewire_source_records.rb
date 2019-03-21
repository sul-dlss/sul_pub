class CreateSciencewireSourceRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :sciencewire_source_records do |t|
      t.text :source_data
      t.integer :pmid
      t.integer :sciencewire_id
      t.integer :lock_version
      t.string :source_fingerprint
      t.boolean :is_active

      t.timestamps
    end
    add_index :sciencewire_source_records, :sciencewire_id
    add_index :sciencewire_source_records, :pmid
  end
end
