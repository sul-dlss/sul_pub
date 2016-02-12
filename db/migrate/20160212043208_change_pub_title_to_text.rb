class ChangePubTitleToText < ActiveRecord::Migration
  def change
    remove_index :publications, :title
    change_column :publications, :title, :text, limit: 65535
    add_index :publications, :title, length: 255

    remove_index :batch_uploaded_source_records, :title
    change_column :batch_uploaded_source_records, :title, :text, limit: 65535
    add_index :batch_uploaded_source_records, :title, length: 255

    change_column :user_submitted_source_records, :title, :text, limit: 65535
  end
end
