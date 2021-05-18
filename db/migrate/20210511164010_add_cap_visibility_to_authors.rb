class AddCapVisibilityToAuthors < ActiveRecord::Migration[6.0]
  def change
    add_column :authors, :cap_visibility, :string
  end
end
