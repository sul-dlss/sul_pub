class UserSubmittedSourceRecord < ActiveRecord::Base
  attr_accessible :is_active, :lock_version, :source_data, :source_fingerprint, :title, :year, :publication_id, :author_id
  belongs_to :publication

  def self.find_or_initialize_by_source_data data

    fingerprint = Digest::SHA2.hexdigest(data)

    r = UserSubmittedSourceRecord.find_or_initialize_by_source_fingerprint fingerprint

    if r.new_record?
      r.source_data = data
    end

    r
  end
end
