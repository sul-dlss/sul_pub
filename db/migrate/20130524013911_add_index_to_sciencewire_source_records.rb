class AddIndexToSciencewireSourceRecords < ActiveRecord::Migration
  def change
  	add_index :sciencewire_source_records, :sciencewire_id
  	add_index :sciencewire_source_records, :pmid
  end
end
