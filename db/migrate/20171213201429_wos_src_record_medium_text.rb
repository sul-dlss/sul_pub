# This migration was created when Argo ran on MySQL. The :mediumtext datatype
# does not exist in Postgres, and this field is now an unlimited :text field.
# This migration is a no-op. Left the former migrations commented out for
# posterity.
class WosSrcRecordMediumText < ActiveRecord::Migration[4.2]
  def up
    # change_column :web_of_science_source_records, :source_data, :mediumtext
  end

  def down
    # change_column :web_of_science_source_records, :source_data, :text
  end
end
