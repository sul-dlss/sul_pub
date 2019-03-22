class AddTypeToPublications < ActiveRecord::Migration[4.2]
  def change
    add_column :publications, :type, :string
  end
end
