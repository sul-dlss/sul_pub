class SourceRecord < ActiveRecord::Base
  attr_accessible :title, :lock_version, :original_source_id, :source_data, :source_name, :source_data_type, :is_active, :is_local_only, :year, :publication_id, :source_fingerprint
  belongs_to :publication
end

