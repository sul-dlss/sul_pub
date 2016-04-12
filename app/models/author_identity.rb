class AuthorIdentity < ActiveRecord::Base
  has_paper_trail on: [:destroy]

  belongs_to :author

  enum identity_type: { alternate: 0 } # may be expanded to include other types

  # required attributes will raise exceptions if nil
  validates :author, :first_name, :last_name, :identity_type, presence: true
end
