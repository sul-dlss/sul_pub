class RemoveXmlFromPublication < ActiveRecord::Migration[4.2]
  def change
    remove_column :publications, :xml, :string
  end
end
