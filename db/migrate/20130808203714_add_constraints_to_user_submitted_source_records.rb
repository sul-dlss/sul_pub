class AddConstraintsToUserSubmittedSourceRecords < ActiveRecord::Migration
  def change
    add_index :user_submitted_source_records, :source_fingerprint, unique: true
  end
end
