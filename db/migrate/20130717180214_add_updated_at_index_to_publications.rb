class AddUpdatedAtIndexToPublications < ActiveRecord::Migration[4.2]
  def change
    add_index :publications, :updated_at
  end
end
