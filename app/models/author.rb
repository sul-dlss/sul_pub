require 'set'

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

  attr_accessor :alt_identities_changed, :harvested

  # these methods allow us to consider any changes to the number of alternative identities
  #   as a change to the author, which is useful to ensure harvesting is triggered when an author identity is updated
  def make_harvestable
    self.alt_identities_changed = true
    self.harvested = false
  end

  def should_harvest?
    (alt_identities_changed || changed?) && !harvested
  end

  # if we reload the author, reset the alt_identities_changed setting, so it can be recomputed if needed
  def reload
    super
    self.alt_identities_changed = false
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

  # Drops and replaces all author identities and re-imports them from the given data if there is a change.
  # @param [Array<Hash>] import_settings are as-is data from the CAP API
  def mirror_author_identities(import_settings)
    return unless import_settings.present?
    # Return if no changes in author identifies.
    return false if author_identities_set == import_author_identities_set(import_settings)
    transaction do
      author_identities.clear # drop all existing identities
      import_settings.each do |i|
        attribs = import_setting_to_attribs(i)
        # ensure that we have a *new* identity worth saving
        next unless author_identity_different?(attribs)
        # can't call create! on an unsaved record
        new_record? ? author_identities.build(attribs) : author_identities.create!(attribs)
      end
    end
    make_harvestable
    true
  end

  # Transforms an import setting to attributes.
  # @param [Hash] import_setting from the CAP API
  def import_setting_to_attribs(import_setting)
    # required attributes
    attribs = {
      first_name: import_setting['firstName'],
      last_name:  import_setting['lastName']
    }
    # optional attributes
    attribs[:middle_name] = import_setting['middleName'] if import_setting['middleName'].present?
    attribs[:email] = import_setting['email'] if import_setting['email'].present?
    attribs[:institution] = import_setting['institution'] if import_setting['institution'].present?
    attribs[:start_date] = import_setting['startDate']['value'] if import_setting['startDate'].present?
    attribs[:end_date] = import_setting['endDate']['value'] if import_setting['endDate'].present?
    attribs
  end

  # Returns a string representing an author identity that can be compared another author identity.
  # @param [String] first_name First name of the author.
  # @param [String] middle_name Middle name of the author or nil.
  # @param [String] last_name Last name of the author.
  # @param [String] institution Institution of the author or nil.
  def normalize_author_identity(first_name, middle_name, last_name, institution)
    "First: #{first_name} Middle: #{middle_name} Last: #{last_name} Institution: #{institution}"
  end

  # Returns existing author identities as set of normalized strings.
  def author_identities_set
    author_identities.map do |ident|
      normalize_author_identity(ident.first_name, ident.middle_name || 'None',
                                ident.last_name, ident.institution || 'None')
    end.to_s
  end

  # Returns author identity from import setting as set of normalized strings.
  # @param [Hash] import_setting from the CAP API
  def import_author_identities_set(import_settings)
    import_settings.map do |import_setting|
      # ensure that we have a *new* identity worth saving
      next unless author_identity_different?(import_setting_to_attribs(import_setting))
      normalize_author_identity(import_setting['firstName'], import_setting.fetch('middleName', 'None'),
                                import_setting['lastName'], import_setting.fetch('institution', 'None'))
    end.compact.to_s # we need to compact to reject the nils we get from skipping identities that are identical to the primary
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

    # Returns true if identity of this author (i.e., primary author represented by this model)
    # do not match the provided attributes from an import setting.
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
