class Contribution < ActiveRecord::Base
  # Allowed values for visibility
  VISIBILITY_VALUES = %w(public private).freeze
  # Allowed values for status
  STATUS_VALUES = %w(approved denied new unknown).freeze

  belongs_to :publication, required: true, inverse_of: :contributions
  belongs_to :author, required: true, inverse_of: :contributions

  has_one :publication_identifier, -> { where("publication_identifiers.identifier_type = 'PublicationItemId'") },
          class_name: 'PublicationIdentifier',
          foreign_key: 'publication_id',
          primary_key: 'publication_id'

  validates :visibility, inclusion: { in: VISIBILITY_VALUES }, allow_nil: true # TODO: disallow nil
  validates :status, inclusion: { in: STATUS_VALUES }, allow_nil: true         # TODO: disallow nil

  def cap_profile_id
    (author.cap_profile_id if author) || self[:cap_profile_id]
  end

  def self.authorship_valid?(authorship)
    author_valid?(authorship) && valid_fields?(authorship)
  end

  def self.author_valid?(contrib)
    contrib = contrib.with_indifferent_access
    if ! contrib[:sul_author_id].blank?
      Author.exists?(contrib[:sul_author_id])
    elsif ! contrib[:cap_profile_id].blank?
      Author.exists?(cap_profile_id: contrib[:cap_profile_id])
    else
      # there must be at least one valid author id
      false
    end
  end

  def self.valid_fields?(contrib)
    featured_valid?(contrib) &&
      status_valid?(contrib) &&
      visibility_valid?(contrib)
  end

  # @return [Boolean]
  def self.visibility_valid?(contrib)
    contrib = contrib.with_indifferent_access
    VISIBILITY_VALUES.include? contrib[:visibility].to_s.downcase
  end

  # @return [Boolean]
  def self.status_valid?(contrib)
    contrib = contrib.with_indifferent_access
    STATUS_VALUES.include? contrib[:status].to_s.downcase
  end

  # Allowed values for featured are true and false
  # @return [Boolean]
  def self.featured_valid?(contrib)
    contrib = contrib.with_indifferent_access
    contrib[:featured].to_s =~ /true|false/i ? true : false
  end

  def to_pub_hash
    {
      cap_profile_id: cap_profile_id,
      sul_author_id: author_id,
      status: status,
      visibility: visibility,
      featured: featured
    }
  end
end
