class PubmedSourceRecord < ActiveRecord::Base
  attr_accessible :is_active, :lock_version, :pmid, :source_data, :source_fingerprint
  #validates_uniqueness_of :pmid
end
