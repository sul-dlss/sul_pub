class SciencewireSourceRecord < ActiveRecord::Base
  attr_accessible :is_active, :lock_version, :pmid, :sciencewire_id, :source_data, :source_fingerprint
  validates_uniqueness_of :sciencewire_id
end
