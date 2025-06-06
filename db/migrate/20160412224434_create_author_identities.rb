class CreateAuthorIdentities < ActiveRecord::Migration[4.2]
  def change
    create_table :author_identities do |t|
      t.belongs_to :author,       index: true, foreign_key: true, null: false
      t.integer :identity_type,   limit: 1, default: 0, null: false # enum: :alternate = 0, :official, :preferred, or :primary
      t.string :first_name,       limit: 255, null: false
      t.string :middle_name,      limit: 255
      t.string :last_name,        limit: 255, null: false
      t.string :email,            limit: 255
      t.string :institution,      limit: 255 # use null for "any" institution
      t.date :start_date
      t.date :end_date

      t.timestamps null: false
    end
  end
end
