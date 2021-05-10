class AddOrcididToAuthors < ActiveRecord::Migration[6.0]
  def change
    add_column :authors, :orcidid, :string
  end
end
