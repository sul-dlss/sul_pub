class WosSrcRecordMediumText < ActiveRecord::Migration[4.2]
  def up
    if ActiveRecord::Base.connection.adapter_name.match?(/mysql/i)
      change_column :web_of_science_source_records, :source_data, :mediumtext
    else
      change_column :web_of_science_source_records, :source_data, :text
    end
  end

  def down
    change_column :web_of_science_source_records, :source_data, :text
  end
end
