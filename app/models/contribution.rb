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

  def self.valid_authorship_hash?(authorship_hash)
    # puts authorship_hash.to_s
    authorship_hash.all? do |contrib|
      authors_valid?(contrib) && all_fields_present?(contrib)
    end
  end

  def self.authors_valid?(contrib)
    if ! contrib[:sul_author_id].blank?
      Author.exists?(contrib[:sul_author_id])
    elsif ! contrib[:cap_profile_id].blank?
      Author.exists?(cap_profile_id: contrib[:cap_profile_id])
    else
      # there must be at least one valid author id
      false
    end
  end

  def self.all_fields_present?(contrib)
    ! (
        contrib[:featured].nil? ||
        contrib[:status].blank? ||
        contrib[:visibility].blank?
      )
  end

  def self.find_or_create_by_author_and_publication(author, publication)
    find_or_create_by_author_id_and_publication_id(author.id, publication.id)
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
