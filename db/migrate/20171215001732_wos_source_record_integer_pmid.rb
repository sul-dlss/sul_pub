class WosSourceRecordIntegerPmid < ActiveRecord::Migration[4.2]
  def up
    if ActiveRecord::Base.connection.adapter_name.match?(/mysql/i)
      change_column :web_of_science_source_records, :pmid, :integer
    else
      change_column :web_of_science_source_records, :pmid, :integer, using: 'pmid::integer'
    end
  end

  def down
    change_column :web_of_science_source_records, :pmid, :string
  end
end
