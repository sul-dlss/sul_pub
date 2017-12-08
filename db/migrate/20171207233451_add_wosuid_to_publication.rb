class AddWosuidToPublication < ActiveRecord::Migration
  def change
    add_column :publications, :wos_uid, :string
    add_index :publications, :wos_uid
  end
end
