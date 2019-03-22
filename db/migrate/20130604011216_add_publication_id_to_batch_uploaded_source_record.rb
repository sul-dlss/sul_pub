class AddPublicationIdToBatchUploadedSourceRecord < ActiveRecord::Migration[4.2]
  def change
    add_column :batch_uploaded_source_records, :publication_id, :integer
  end
end
