class CreatePublicationIdentifiers < ActiveRecord::Migration[4.2]
  def change
    create_table :publication_identifiers do |t|
      t.integer :publication_id
      t.string :identifier_type
      t.string :identifier_value
      t.string :identifier_uri
      t.string :certainty

      t.timestamps
    end

    add_index :publication_identifiers, [:publication_id, :identifier_type], name: 'pub_identifier_index_by_type_and_pub'
    add_index :publication_identifiers, [:identifier_type, :publication_id], name: 'pub_identifier_index_by_pub_and_type'
    add_index :publication_identifiers, :publication_id
    add_index :publication_identifiers, :identifier_type
  end
end
