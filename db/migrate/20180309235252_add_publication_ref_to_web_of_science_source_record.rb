class AddPublicationRefToWebOfScienceSourceRecord < ActiveRecord::Migration[4.2]
  def change
    add_reference :web_of_science_source_records, :publication, index: {unique: true}, foreign_key: true
  end
end
