class CreateOrcidSourceRecords < ActiveRecord::Migration[6.0]
  def change
    create_table :orcid_source_records do |t|
      t.text :source_data
      t.bigint :last_modified_date
      t.string :orcidid
      t.string :put_code
      t.string :source_fingerprint

      t.timestamps
    end
    add_reference :orcid_source_records, :publication, index: {unique: true}, foreign_key: true, type: :integer
    add_index :orcid_source_records, [:orcidid, :put_code], unique: true
  end
end
