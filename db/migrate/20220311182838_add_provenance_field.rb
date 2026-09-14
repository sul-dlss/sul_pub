class AddProvenanceField < ActiveRecord::Migration[6.1]
  def change
    add_column :publications, :provenance, :string
    add_index :publications, :provenance
  end
end
