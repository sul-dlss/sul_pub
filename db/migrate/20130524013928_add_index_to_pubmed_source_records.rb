class AddIndexToPubmedSourceRecords < ActiveRecord::Migration
  def change
  	add_index :pubmed_source_records, :pmid
  end
end
