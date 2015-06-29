class UserSubmittedSourceRecord < ActiveRecord::Base
  validates_uniqueness_of :source_fingerprint
  belongs_to :publication

  before_save do
    self.source_fingerprint = Digest::SHA2.hexdigest(source_data) if source_data_changed?
  end

  def self.find_or_initialize_by_source_data data
    UserSubmittedSourceRecord.find_or_initialize_by source_fingerprint: Digest::SHA2.hexdigest(data) do |r|
      r.source_data = data
    end
  end
end
