class Contribution < ActiveRecord::Base

  def cap_profile_id
    (author.cap_profile_id if author) || self[:cap_profile_id]
  end

  belongs_to :publication
  belongs_to :author
  # has_one :publication_identifier, :foreign_key => "publication_id"
  has_one :publication_identifier, -> { where("publication_identifiers.identifier_type = 'PublicationItemId'") },
          class_name: 'PublicationIdentifier',
          foreign_key: 'publication_id',
          primary_key: 'publication_id'
  # has_one :population_membership, :foreign_key => "author_id"

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

  # Allowed values for visibility
  VISIBILITY_VALUES = %w(public private).freeze

  # @return [Boolean]
  def self.visibility_valid?(contrib)
    contrib = contrib.with_indifferent_access
    VISIBILITY_VALUES.include? contrib[:visibility].to_s.downcase
  end

  # Allowed values for status
  STATUS_VALUES = %w(approved denied new unknown).freeze

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

  def self.find_or_create_by_author_and_publication(author, publication)
    find_or_create_by(author_id: author.id, publication_id: publication.id)
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
