class BatchUploadedSourceRecord < ActiveRecord::Base
  attr_accessible :author_id, :publication_id, :batch_name, :bibtex_source_data, :cap_profile_id, :error_message, :is_active, :source_fingerprint, :successful_import, :sunet_id, :title, :year
  belongs_to :publication
end
