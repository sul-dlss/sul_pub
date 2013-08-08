class UserSubmittedSourceRecord < ActiveRecord::Base
  attr_accessible :is_active, :lock_version, :source_data, :source_fingerprint, :title, :year, :publication_id, :author_id
  validates_uniqueness_of :source_fingerprint
  belongs_to :publication

  before_save do
    self.source_fingerprint = Digest::SHA2.hexdigest(source_data) if source_data_changed?
  end

  def self.find_or_initialize_by_source_data data

    r = UserSubmittedSourceRecord.find_or_initialize_by_source_fingerprint Digest::SHA2.hexdigest(data)

    if r.new_record?
      r.source_data = data
    end

    r
  end

end
