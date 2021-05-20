class AddPutCodeToContribution < ActiveRecord::Migration[6.0]
  def change
    add_column :contributions, :orcid_put_code, :string
    add_index :contributions, :orcid_put_code
  end
end
