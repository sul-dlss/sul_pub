class CreateAuthorIdentifiers < ActiveRecord::Migration
  def change
    create_table :author_identifiers do |t|
      t.integer :author_id
      t.string :identifier_type
      t.string :identifier_value

      t.timestamps
    end
  end
end
