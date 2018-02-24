class AuthorIdentity < ActiveRecord::Base
  has_paper_trail on: [:destroy]
  belongs_to :author, inverse_of: :author_identities

  # required attributes will raise exceptions if nil
  validates :author, :first_name, :last_name, presence: true

  # Converts an AuthorIdentity object to an AuthorAttributes object for use by other classes
  def to_author_attributes
    ScienceWire::AuthorAttributes.new(
      Agent::AuthorName.new(last_name, first_name, middle_name),
      email,
      # there is no seed list for AuthorIdentity because it is not needed for dumb search
      # but there is a seed list that can come from Author#approved_sciencewire_ids
      # if needed in the future
      [],
      Agent::AuthorInstitution.new(institution),
      start_date,
      end_date
    )
  end

  # Don't search unless valid institution is provided
  def searchable_institution?
    institution.present? && institution != 'all' && institution != '*'
  end
end
