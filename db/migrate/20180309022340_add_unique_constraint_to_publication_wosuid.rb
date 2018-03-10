class AddUniqueConstraintToPublicationWosuid < ActiveRecord::Migration
  def down
    remove_index :web_of_science_source_records, :source_fingerprint if index_exists?(:web_of_science_source_records, :source_fingerprint)
    remove_index :web_of_science_source_records, :uid if index_exists?(:web_of_science_source_records, :uid)
    remove_index :publications, :wos_uid
    puts "NOTE: Any deleted duplicate WebOfScienceSourceRecord rows cannot be restored here"
  end

  def up
    uids = WebOfScienceSourceRecord.group(:uid).having("count(uid) > 1").pluck(:uid)
    marked_for_death = []
    WebOfScienceSourceRecord.where(uid: uids).order(:created_at).group_by(&:uid).each do |_uid, recs|
      marked_for_death.concat(recs.map(&:id)[1..-1]) # skip the first (0th) record for each uid
    end
    WebOfScienceSourceRecord.delete(marked_for_death) # delete the rest, all at once

    remove_index :publications, :wos_uid if index_exists?(:publications, :wos_uid)
    add_index :publications, :wos_uid, unique: true, using: :btree

    remove_index :web_of_science_source_records, name: :web_of_science_uid_index
    remove_index :web_of_science_source_records, :uid if index_exists?(:web_of_science_source_records, :uid)
    add_index :web_of_science_source_records, :uid, unique: true, using: :btree

    remove_index :web_of_science_source_records, :source_fingerprint if index_exists?(:web_of_science_source_records, :source_fingerprint)
    add_index :web_of_science_source_records, :source_fingerprint, unique: true, using: :btree
  end
end
