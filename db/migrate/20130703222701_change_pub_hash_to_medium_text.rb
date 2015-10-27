class ChangePubHashToMediumText < ActiveRecord::Migration
  def change
    change_column :publications, :pub_hash, :text, limit: 16_777_215
  end
end
