class CreatePublications < ActiveRecord::Migration
  def change
    create_table :publications do |t|
      t.integer :same_as_publications_id
      t.boolean :active
      t.boolean :deleted
      t.string :title
      t.integer :year
      t.integer :lock_version
      t.text :xml
      t.text :pub_hash
      t.integer :pmid
      t.integer :sciencewire_id
      t.timestamps
    end
  end
end
