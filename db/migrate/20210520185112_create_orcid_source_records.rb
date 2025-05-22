class CreateOrcidSourceRecords < ActiveRecord::Migration[6.0]
  def change
    create_table :orcid_source_records do |t|
      if ActiveRecord::Base.connection.adapter_name.match?(/mysql/i)
        # `:text` column with 16MB is the same as MySQL's MEDIUMTEXT but works on sqlite3
        t.text :source_data, limit: 16_777_215
      else
        t.text :source_data
      end
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
