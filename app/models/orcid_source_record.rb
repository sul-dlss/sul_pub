# frozen_string_literal: true

class OrcidSourceRecord < ApplicationRecord
  belongs_to :publication, inverse_of: :orcid_source_record, optional: true

  serialize :source_data, JSON
end
