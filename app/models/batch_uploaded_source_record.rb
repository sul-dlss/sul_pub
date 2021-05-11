# frozen_string_literal: true

class BatchUploadedSourceRecord < ActiveRecord::Base
  belongs_to :publication
end
