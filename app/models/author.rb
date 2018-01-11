class Author < ActiveRecord::Base
  has_paper_trail on: [:destroy]
  validates :cap_profile_id, uniqueness: true, presence: true

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

  # Provide consistent API for Author and AuthorIdentity
  alias_attribute :first_name, :preferred_first_name
  alias_attribute :middle_name, :preferred_middle_name
  alias_attribute :last_name, :preferred_last_name

  # Provide consistent API for Author and AuthorIdentity
  # The default institution is set in
  # Settings.HARVESTER.INSTITUTION.name
  # @return [String] institution
  def institution
    Settings.HARVESTER.INSTITUTION.name
  end

  # TODO: CAP could provide dates for Stanford affiliation
  # Provide consistent API for Author and AuthorIdentity
  # @return [nil]
  def start_date
    nil
  end

  # TODO: CAP could provide dates for Stanford affiliation
  # Provide consistent API for Author and AuthorIdentity
  # @return [nil]
  def end_date
    nil
  end

  # @return [Array<Integer>] ScienceWireIds for approved publications
  def approved_sciencewire_ids
    publications.where("contributions.status = 'approved'")
                .where.not(sciencewire_id: nil)
                .pluck(:sciencewire_id)
                .uniq
  end

  has_many :contributions, dependent: :destroy, after_add: :contributions_changed_callback, after_remove: :contributions_changed_callback do
    def build_or_update(publication, contribution_hash = {})
      c = where(publication_id: publication.id).first_or_initialize

      c.assign_attributes contribution_hash.merge(publication_id: publication.id)
      if c.persisted?
        c.save
        publication.pubhash_needs_update!
      else
        self << c
      end

      c
    end
  end

  # TODO: update the publication cached pubhash
  def contributions_changed_callback(*_args)
  end

  has_many :publications, through: :contributions
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

  # @param [Hash] auth_hash data as-is from CAP API
  def update_from_cap_authorship_profile_hash(auth_hash)
    seed_hash = Author.build_attribute_hash_from_cap_profile(auth_hash)
    assign_attributes seed_hash
    mirror_author_identities(auth_hash['importSettings'])
  end

  # Drops and replaces all author identities and re-imports them from the given data
  # @param [Array<Hash>] import_settings are as-is data from the CAP API
  def mirror_author_identities(import_settings)
    return unless import_settings.present?
    transaction do
      author_identities.clear unless new_record? # drop all existing identities

      import_settings.each do |i|
        # create record with required attributes
        ai = AuthorIdentity.new(
          author:         self,
          identity_type:  :alternate,
          first_name:     i['firstName'],
          last_name:      i['lastName']
        )
        # update record with optional attributes
        ai.middle_name = i['middleName']         if i['middleName'].present?
        ai.email = i['email']                    if i['email'].present?
        ai.institution = i['institution']        if i['institution'].present?
        ai.start_date = i['startDate']['value']  if i['startDate'].present?
        ai.end_date = i['endDate']['value']      if i['endDate'].present?

        # ensure that we have a *new* identity worth saving
        ai.save! if author_identity_different?(ai)
      end
    end
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
    seed_hash[:emails_for_harvest] = seed_hash[:email] # TODO: duplicate of :email
    legal_name = profile['names']['legal']
    pref_name = profile['names']['preferred']
    seed_hash[:official_first_name] = legal_name['firstName'] || ''
    seed_hash[:official_middle_name] = legal_name['middleName'] || ''
    seed_hash[:official_last_name] = legal_name['lastName'] || ''
    seed_hash[:cap_first_name] = pref_name['firstName'] || ''
    seed_hash[:cap_middle_name] = pref_name['middleName'] || ''
    seed_hash[:cap_last_name] = pref_name['lastName'] || ''
    # TODO: preferred names are duplicates of :cap names
    seed_hash[:preferred_first_name] = seed_hash[:cap_first_name]
    seed_hash[:preferred_middle_name] = seed_hash[:cap_middle_name]
    seed_hash[:preferred_last_name] = seed_hash[:cap_last_name]
    seed_hash
  end

  # @param [String] CAP Profile ID
  # @param [Cap::Client] cap_client
  # @return [Author] newly fetched, created and saved Author object
  def self.fetch_from_cap_and_create(profile_id, cap_client = Cap::Client.new)
    profile_hash = cap_client.get_auth_profile(profile_id)
    a = Author.new
    a.update_from_cap_authorship_profile_hash(profile_hash)
    a.save!
    a
  end

  def harvestable?
    active_in_cap && cap_import_enabled
  end

  private

    # @param [AuthorIdentity] author_identity is the candidate versus `self`'s identity
    # @return [Boolean] Is this author's identity different than our current identity?
    def author_identity_different?(author_identity)
      !(
        # not the identical identity where Author is assumed to be Stanford University
        # checks in order of likelihood of changes
        # note that this code works for nil/empty string comparisons by calling `to_s`
        first_name.to_s.casecmp(author_identity.first_name.to_s) == 0 &&
        middle_name.to_s.casecmp(author_identity.middle_name.to_s) == 0 &&
        last_name.to_s.casecmp(author_identity.last_name.to_s) == 0 &&
        institution.to_s.casecmp(author_identity.institution.to_s) == 0
      )
    end
end
