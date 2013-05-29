class AddDetailsToPublications < ActiveRecord::Migration
  def change
    add_column :publications, :pages, :string
    add_column :publications, :issn, :string
  end
end
