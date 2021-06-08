# frozen_string_literal: true

require 'set'

class Author < ApplicationRecord
  # Allowed values for visibility
  VISIBILITY_VALUES = %w[public private stanford].freeze

  has_paper_trail on: [:destroy]
  validates :cap_profile_id, uniqueness: true, presence: true
  validates :orcidid, format: { with: %r{https://(sandbox.)*orcid.org/\d{4}-\d{4}-\d{4}-\d{3}(\d|[xX])\z} }, allow_blank: true

  has_many :author_identities, dependent: :destroy, autosave: true
  has_many :contributions, dependent: :destroy
  has_many :publications, through: :contributions

  # nil values allowed because we have historical records without visibility info, for which cap API
  # will no longer have updated author info (e.g. for authors who are no longer at Stanford)
  validates :cap_visibility, inclusion: { in: VISIBILITY_VALUES }, allow_nil: true

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

  # indicates if the LastName, FirstInitial form for this user is unique within our author database
  #  (including any alternate identities that include Stanford as an institution)
  #  also checks to see if there are alternate identities with institutions other than Stanford, which is problematic, and should be considered ambiguous
  def unique_first_initial?
    return false unless first_name && last_name # this method only works if you have a complete first and last name

    !(first_initial_not_unique? || author_identities_not_unique?)
  end

  def first_initial_not_unique?
    self.class.where_first_name_like_and_last_name_equal(first_name[0], last_name).size > 1
  end

  def author_identities_not_unique?
    author_identities.map do |author_identity|
      (author_identity.institution.present? && author_identity.institution.exclude?('Stanford')) ||
        self.class.where_first_name_like_and_last_name_equal(author_identity.first_name[0],
                                                             author_identity.last_name,
                                                             exclude_author_id: author_identity.author_id).size > 1
    end.include?(true)
  end

  def self.where_first_name_like_and_last_name_equal(first_name_prefix, last_name, exclude_author_id: nil)
    relation = where('preferred_first_name like ?', "#{first_name_prefix}%")
               .where(preferred_last_name: last_name)
    relation = relation.where.not(id: exclude_author_id) if exclude_author_id

    relation
  end

  # @param [Hash] auth_hash data as-is from CAP API
  def update_from_cap_authorship_profile_hash(auth_hash)
    assign_attributes Author.build_attribute_hash_from_cap_profile(auth_hash)
    mirror_author_identities(auth_hash['importSettings'])
  end

  # Drops and replaces all author identities and re-imports them from the given data if there is a change.
  # @param [Array<Hash>] import_settings are as-is data from the CAP API
  def mirror_author_identities(import_settings)
    return if import_settings.blank?
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
      last_name: import_setting['lastName']
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
  # rubocop:disable Metrics/AbcSize
  def self.build_attribute_hash_from_cap_profile(auth_hash)
    # sunetid/ university id/ ca licence ---- at least one is expected
    seed_hash = {
      cap_profile_id: auth_hash['profileId'],
      active_in_cap: auth_hash['active'],
      cap_import_enabled: auth_hash['importEnabled'],
      cap_visibility: auth_hash['visibility']
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

  # rubocop:enable Metrics/AbcSize
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
  # @param [String] ORCID put-code
  # @return [Contribution]
  def assign_pub(pub, orcid_put_code: nil)
    unless pub # do not attempt to assign if no pub provided
      logger.warn "nil publication assignment for author id #{id}"
      return
    end
    raise 'Author must be saved before association' unless persisted?

    contribution = pub.contributions.find_or_initialize_by(author_id: id) do |contrib|
      contrib.assign_attributes(
        cap_profile_id: cap_profile_id,
        featured: false, status: 'new', visibility: 'private',
        orcid_put_code: orcid_put_code
      )
    end
    return contribution unless contribution.new_record?

    contribution.save!
    pub.pubhash_needs_update!
    pub.save!
    contribution
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
