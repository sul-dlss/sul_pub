class WebOfScienceSourceRecordIds < ActiveRecord::Migration[4.2]
  def change
    add_column :web_of_science_source_records, :doi, :string
    add_column :web_of_science_source_records, :pmid, :string

    add_index :web_of_science_source_records, :doi, name: 'web_of_science_doi_index'
    add_index :web_of_science_source_records, :pmid, name: 'web_of_science_pmid_index'
  end
end
