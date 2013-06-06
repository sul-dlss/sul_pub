class AddCaliforniaPhysicianLicenceToAuthors < ActiveRecord::Migration
  def change
    add_column :authors, :california_physician_license, :string
    add_index :authors, :california_physician_license
    add_index :authors, :university_id
  end
end
