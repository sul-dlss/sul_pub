# frozen_string_literal: true

class AuthorIdentity < ApplicationRecord
  has_paper_trail on: [:destroy]
  belongs_to :author, inverse_of: :author_identities

  # required attributes will raise exceptions if nil
  validates :author, :first_name, :last_name, presence: true
  before_validation :set_first_name_if_missing

  # if the first name is missing, default to the preferred first name from the main author record to allow
  #   alternate institution information to be preserved and used when querying
  def set_first_name_if_missing
    self.first_name = author.first_name if author && first_name.blank?
  end

  # Don't search unless valid institution is provided
  def searchable_institution?
    institution.present? && institution != 'all' && institution != '*'
  end
end
