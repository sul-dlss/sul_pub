class AddOrgCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :code, null: false, index: { unique: true }
      t.string :org_type
      t.string :alias
      t.integer :group_id, null: true, index: true
      t.integer :lft, null: false, index: true
      t.integer :rgt, null: false, index: true
      t.integer :depth, null: false, default: 0
      t.integer :children_count, null: false, default: 0
      t.timestamps
    end

    create_table :author_organizations do |t|
      t.integer :author_id
      t.integer :organization_id
      t.string :affiliation
      t.timestamps
    end
  end
end
