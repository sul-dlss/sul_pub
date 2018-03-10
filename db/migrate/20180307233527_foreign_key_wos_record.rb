class ForeignKeyWosRecord < ActiveRecord::Migration
  def change
    add_foreign_key :publications, :web_of_science_source_records, column: :wos_uid, primary_key: :uid
  end
end
