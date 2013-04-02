class SourceRecord < ActiveRecord::Base
  attr_accessible :human_readable_title, :lock_version, :original_source_id, :source_data, :source_name, :source_data_type
  has_many :publications_source_records
  has_many :publications, :through => :publications_source_records
end
