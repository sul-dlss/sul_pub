class CreateAuthorNames < ActiveRecord::Migration
  def change
    create_table :author_names do |t|
      t.integer :author_id
      t.string :first_name
      t.string :last_name
      t.string :middle_name

      t.timestamps
    end
  end
end
