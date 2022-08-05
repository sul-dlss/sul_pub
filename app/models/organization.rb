# frozen_string_literal: true

class Organization < ApplicationRecord
  acts_as_nested_set parent_column: :group_id

  validates :code, uniqueness: true, presence: true
  validates :name, presence: true
  validates :org_type, presence: true

  # hierarchy
  belongs_to :group, class_name: 'Organization', optional: true
  has_many :organizations, foreign_key: 'group_id', dependent: :destroy, inverse_of: :organization

  has_many :author_organizations, dependent: :destroy
  has_many :authors, through: :author_organizations
end
