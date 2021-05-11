# frozen_string_literal: true

# Common superclass for ActiveRecord-based models
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
