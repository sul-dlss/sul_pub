class AddPublicationIdToBatchUploadedSourceRecord < ActiveRecord::Migration
  def change
    add_column :batch_uploaded_source_records, :publication_id, :integer
  end
end
