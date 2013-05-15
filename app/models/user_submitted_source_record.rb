class UserSubmittedSourceRecord < ActiveRecord::Base
  attr_accessible :is_active, :lock_version, :source_data, :source_fingerprint, :title, :year, :publication_id, :author_id
  belongs_to :publication
end
