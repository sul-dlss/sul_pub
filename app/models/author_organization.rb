# frozen_string_literal: true

class AuthorOrganization < ApplicationRecord
  belongs_to :author
  belongs_to :organization
end
