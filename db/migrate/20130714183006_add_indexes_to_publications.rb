class AddIndexesToPublications < ActiveRecord::Migration
  def change
    add_index :publications, :issn
    add_index :publications, :title
    add_index :publications, :pages
    add_index :publications, :year
  end
end
