class RenameTypeColumninPublications < ActiveRecord::Migration
  def change
    rename_column :publications, :type, :publication_type
  end
end
