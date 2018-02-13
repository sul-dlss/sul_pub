class WosSourceRecordIdentifiers < ActiveRecord::Migration
  def change
    add_column :web_of_science_source_records, :identifiers, :mediumtext
  end
end
