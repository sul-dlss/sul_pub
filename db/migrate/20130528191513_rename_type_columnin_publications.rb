class RenameTypeColumninPublications < ActiveRecord::Migration[4.2]
  def change
    rename_column :publications, :type, :publication_type
  end
end
