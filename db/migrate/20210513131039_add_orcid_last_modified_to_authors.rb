class AddOrcidLastModifiedToAuthors < ActiveRecord::Migration[6.0]
  def change
    add_column :authors, :orcid_last_modified, :bigint
  end
end
