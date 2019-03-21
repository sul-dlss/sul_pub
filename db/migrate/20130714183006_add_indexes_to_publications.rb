class AddIndexesToPublications < ActiveRecord::Migration[4.2]
  def change
    add_index :publications, :issn
    add_index :publications, :title
    add_index :publications, :pages
    add_index :publications, :year
  end
end
