class CreatePublications < ActiveRecord::Migration
  def change
    create_table :publications do |t|
      t.integer :same_as_publications_id
      t.boolean :active
      t.boolean :deleted
      t.string :human_readable_title
      t.integer :lock_version
      t.text :xml
      t.text :json
      t.timestamps
    end
  end
end
