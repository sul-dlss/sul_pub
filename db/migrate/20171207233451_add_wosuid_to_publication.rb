class AddWosuidToPublication < ActiveRecord::Migration[4.2]
  def change
    add_column :publications, :wos_uid, :string
    add_index :publications, :wos_uid
  end
end
