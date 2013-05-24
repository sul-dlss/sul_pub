class AddIndexToPublications < ActiveRecord::Migration
  def change
  	add_index :publications, :sciencewire_id
  	add_index :publications, :pmid
end
end
