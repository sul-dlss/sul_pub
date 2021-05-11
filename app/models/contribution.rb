# frozen_string_literal: true

class Contribution < ActiveRecord::Base
  # Allowed values for visibility
  VISIBILITY_VALUES = %w[public private].freeze
  # Allowed values for status
  STATUS_VALUES = %w[approved denied new unknown].freeze

  belongs_to :publication, required: true, inverse_of: :contributions
  belongs_to :author, required: true, inverse_of: :contributions

  has_one :publication_identifier, -> { where("publication_identifiers.identifier_type = 'PublicationItemId'") },
          class_name: 'PublicationIdentifier',
          foreign_key: 'publication_id',
          primary_key: 'publication_id'

  validates :visibility, inclusion: { in: VISIBILITY_VALUES }, allow_nil: true # TODO: disallow nil
  validates :status, inclusion: { in: STATUS_VALUES }, allow_nil: true         # TODO: disallow nil

  after_initialize :init

  # apply some default values and coercions (lowercasing)
  # @note must use attributes[...] checks here instead of getter methods to support Contribution.select(:id)
  def init
    self.featured   = false if attributes['featured'].nil? # can't use ||=
    self.status     = status.downcase if attributes['status']
    self.visibility = visibility.downcase if attributes['visibility']
  end

  def cap_profile_id
    author&.cap_profile_id || self[:cap_profile_id]
  end

  def self.authorship_valid?(authorship)
    author_valid?(authorship) && valid_fields?(authorship)
  end

  def self.author_valid?(contrib)
    contrib = contrib.with_indifferent_access
    if !contrib[:sul_author_id].blank?
      Author.exists?(contrib[:sul_author_id])
    elsif !contrib[:cap_profile_id].blank?
      Author.exists?(cap_profile_id: contrib[:cap_profile_id])
    else
      # there must be at least one valid author id
      false
    end
  end

  # checks featured, status and visibility
  # @return [Boolean]
  def self.valid_fields?(contrib)
    segment = contrib.with_indifferent_access.slice(:featured, :status, :visibility)
    return false unless segment.size == 3
    return false if segment.values.any?(&:nil?)

    prototype = Contribution.new(segment)
    prototype.validate # we KNOW it won't validate (w/o author and publication), but we check for the other fields
    prototype.errors.messages.slice(:featured, :status, :visibility).empty?
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
