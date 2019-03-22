class AddDetailsToPublications < ActiveRecord::Migration[4.2]
  def change
    add_column :publications, :pages, :string
    add_column :publications, :issn, :string
  end
end
