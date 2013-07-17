class AddUpdatedAtIndexToPublications < ActiveRecord::Migration
  def change
    add_index :publications, :updated_at
  end
end
