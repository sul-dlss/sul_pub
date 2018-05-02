class Author < ActiveRecord::Base
  has_paper_trail on: [:destroy]
  validates :cap_profile_id, uniqueness: true, presence: true

  has_many :author_identities, dependent: :destroy, autosave: true
  has_many :contributions, dependent: :destroy
  has_many :publications, through: :contributions

  # Provide consistent API for Author and AuthorIdentity
  alias_attribute :first_name, :preferred_first_name
  alias_attribute :middle_name, :preferred_middle_name
  alias_attribute :last_name, :preferred_last_name

  attr_accessor :number_of_identities_changed

  # these methods allow us to consider any changes to the number of alternative identities
  #   as a change to the author, which is useful to ensure harvesting is triggered when an author identity is updated
  def make_harvestable
    self.number_of_identities_changed = true
  end

  def should_harvest?
    number_of_identities_changed || changed?
  end

  # The default institution is set in Settings.HARVESTER.INSTITUTION.name
  # @return [String] institution
  def institution
    Settings.HARVESTER.INSTITUTION.name
  end

  # @return [Array<Integer>] ScienceWireIds for approved publications
  def approved_sciencewire_ids
    publications.where("contributions.status = 'approved'")
                .where.not(sciencewire_id: nil)
                .pluck(:sciencewire_id)
                .uniq
  end

  # @param [Hash] auth_hash data as-is from CAP API
  def update_from_cap_authorship_profile_hash(auth_hash)
    assign_attributes Author.build_attribute_hash_from_cap_profile(auth_hash)
    mirror_author_identities(auth_hash['importSettings'])
  end

  # Drops and replaces all author identities and re-imports them from the given data
  # @param [Array<Hash>] import_settings are as-is data from the CAP API
  def mirror_author_identities(import_settings)
    return unless import_settings.present?
    starting_identities_count = author_identities.size
    transaction do
      author_identities.clear # drop all existing identities
      import_settings.each do |i|
        # required attributes
        attribs = {
          first_name: i['firstName'],
          last_name:  i['lastName']
        }
        # optional attributes
        attribs[:middle_name] = i['middleName']         if i['middleName'].present?
        attribs[:email      ] = i['email']              if i['email'].present?
        attribs[:institution] = i['institution']        if i['institution'].present?
        attribs[:start_date ] = i['startDate']['value'] if i['startDate'].present?
        attribs[:end_date   ] = i['endDate']['value']   if i['endDate'].present?
        # ensure that we have a *new* identity worth saving
        next unless author_identity_different?(attribs)
        # can't call create! on an unsaved record
        new_record? ? author_identities.build(attribs) : author_identities.create!(attribs)
      end
    end
    make_harvestable if author_identities.size != starting_identities_count # if we have a different number than we started with, something changed!
  end

  # @param [Hash<String => [String, Hash]>] auth_hash
  # @return [Hash<Symbol => String>]
  def self.build_attribute_hash_from_cap_profile(auth_hash)
    # sunetid/ university id/ ca licence ---- at least one is expected
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
    Author.create!(Author.build_attribute_hash_from_cap_profile(profile_hash)) do |a|
      a.mirror_author_identities(profile_hash['importSettings'])
    end
  end

  # @return [Boolean]
  def harvestable?
    active_in_cap && cap_import_enabled
  end

  # @param [Publication]
  # @return [Contribution]
  def assign_pub(pub)
    raise 'Author must be saved before association' unless persisted?
    pub.contributions.find_or_create_by!(author_id: id) do |contrib|
      contrib.assign_attributes(
        cap_profile_id: cap_profile_id,
        featured: false, status: 'new', visibility: 'private'
      )
      pub.pubhash_needs_update! # Add to pub_hash[:authorship]
      pub.save! # contrib.save! not needed
    end
  end

  private

    # @param [Hash<Symbol => String>] attribs the candidate versus `self`'s identity
    # @return [Boolean] Is this author's identity different than our current identity?
    def author_identity_different?(attribs)
      !(
        # not the identical identity where Author is assumed to be Stanford University
        # checks in order of likelihood of changes
        # note that this code works for nil/empty string comparisons by calling `to_s`
        first_name.to_s.casecmp(attribs[:first_name].to_s) == 0 &&
        middle_name.to_s.casecmp(attribs[:middle_name].to_s) == 0 &&
        last_name.to_s.casecmp(attribs[:last_name].to_s) == 0 &&
        institution.to_s.casecmp(attribs[:institution].to_s) == 0
      )
    end
end
