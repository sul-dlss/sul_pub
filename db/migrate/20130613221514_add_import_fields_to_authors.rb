class AddImportFieldsToAuthors < ActiveRecord::Migration[4.2]
  def change
    add_column :authors, :cap_import_enabled, :boolean
    add_column :authors, :emails_for_harvest, :string
  end
end
