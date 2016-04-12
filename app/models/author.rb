class Author < ActiveRecord::Base
  has_paper_trail on: [:destroy]

  has_many :author_identities, dependent: :destroy
  #
  # An Author may have zero or more author identities and this method fetches
  # any matching AuthorIdentity objects tagged as an "alternate"
  #
  # @example
  #   `Author.find_by(1234).alternative_identities.present?`
  #   `Author.find_by(1234).alternative_identities => [AuthorIdentity1, ...]`
  #
  # @return [Array<AuthorIdentity>]
  #
  def alternative_identities
    author_identities.where('identity_type = ?', AuthorIdentity.identity_types[:alternate])
  end

  has_many :contributions, dependent: :destroy, after_add: :contributions_changed_callback, after_remove: :contributions_changed_callback do
    def build_or_update(publication, contribution_hash = {})
      c = where(publication_id: publication.id).first_or_initialize

      c.assign_attributes contribution_hash.merge(publication_id: publication.id)
      if c.persisted?
        c.save
        publication.contributions_changed_callback
      else
        self << c
      end

      c
    end
  end

  # TODO: update the publication cached pubhash
  def contributions_changed_callback(*_args)
  end

  has_many :publications, through: :contributions do
    def approved
      where("contributions.status='approved'")
    end

    def with_sciencewire_id
      where(Publication.arel_table[:sciencewire_id].not_eq(nil))
    end
  end

  has_many :approved_sw_ids, -> { where("contributions.status = 'approved'") }, through: :contributions,
                                                                                class_name: 'PublicationIdentifier',
                                                                                source: :publication_identifier,
                                                                                foreign_key: 'publication_id',
                                                                                primary_key: 'publication_id'

  has_many :approved_publications, -> { where("contributions.status = 'approved'") }, through: :contributions,
                                                                                      class_name: 'Publication',
                                                                                      source: :publication

  # has_many :population_memberships, :dependent => :destroy
  # has_many :author_identifiers, :dependent => :destroy

  def update_from_cap_authorship_profile_hash(auth_hash)
    seed_hash = Author.build_attribute_hash_from_cap_profile(auth_hash)
    assign_attributes seed_hash
  end

  def self.build_attribute_hash_from_cap_profile(auth_hash)
    # key/value not present in hash if value is not there
    # sunetid/ university id/ ca licence ---- at least one will be there
    seed_hash = {
      cap_profile_id: auth_hash['profileId'],
      active_in_cap:  auth_hash['active'],
      cap_import_enabled: auth_hash['importEnabled']
    }
    profile = auth_hash['profile']
    seed_hash[:sunetid] = profile['uid'] || ''
    seed_hash[:university_id] = profile['universityId'] || ''
    seed_hash[:california_physician_license] = profile['californiaPhysicianLicense'] || ''
    seed_hash[:email] = profile['email'] || ''
    seed_hash[:emails_for_harvest] = profile['email'] || ''
    legal_name = profile['names']['legal']
    pref_name = profile['names']['preferred']
    seed_hash[:official_first_name] = legal_name['firstName'] || ''
    seed_hash[:official_middle_name] = legal_name['middleName'] || ''
    seed_hash[:official_last_name] = legal_name['lastName'] || ''
    seed_hash[:cap_first_name] = pref_name['firstName'] || ''
    seed_hash[:cap_middle_name] = pref_name['middleName'] || ''
    seed_hash[:cap_last_name] = pref_name['lastName'] || ''
    seed_hash[:preferred_first_name] = pref_name['firstName'] || ''
    seed_hash[:preferred_middle_name] = pref_name['middleName'] || ''
    seed_hash[:preferred_last_name] = pref_name['lastName'] || ''
    seed_hash
  end

  def self.fetch_from_cap_and_create(profile_id)
    profile_hash = CapHttpClient.new.get_auth_profile(profile_id)
    a = Author.new
    a.update_from_cap_authorship_profile_hash(profile_hash)
    a.save!
    a
  end

  def harvestable?
    active_in_cap && cap_import_enabled
  end
end
