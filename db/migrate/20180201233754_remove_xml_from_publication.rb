class RemoveXmlFromPublication < ActiveRecord::Migration
  def change
    remove_column :publications, :xml, :string
  end
end
