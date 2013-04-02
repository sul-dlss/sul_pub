class CreatePublicationIdentifiers < ActiveRecord::Migration
  def change
    create_table :publication_identifiers do |t|
      t.integer :publication_id
      t.string :identifier_type
      t.string :identifier_value
      t.string :identifier_uri
      t.string :certainty

      t.timestamps
    end
  end
end
