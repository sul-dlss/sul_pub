class Author < ActiveRecord::Base
  attr_accessible :cap_profile_id, :sunetid, :university_id, :california_physician_license, :active_in_cap, :cap_import_enabled, :emails_for_harvest, :email, :cap_first_name, :cap_last_name, :cap_middle_name, :official_first_name, :official_last_name, :official_middle_name, :preferred_first_name, :preferred_last_name, :preferred_middle_name
  has_many :contributions, :dependent => :destroy
  has_many :publications, :through => :contributions do
  	def approved
  		where("contributions.status='approved'")
  	end
  end

  has_many  :approved_sw_ids, :through => :contributions,
          :class_name => "PublicationIdentifier",
          :source => :publication_identifier,
          :foreign_key => "publication_id",
          :primary_key => "publication_id",
          :conditions => "contributions.status = 'approved'"

  has_many  :approved_publications, :through => :contributions,
          :class_name => "Publication",
          :source => :publication,
          :conditions => ['contributions.status = ?','approved']


  #has_many :population_memberships, :dependent => :destroy
  #has_many :author_identifiers, :dependent => :destroy

  def Author.create_from_cap_authorship_profile_hash(auth_hash)

    # key/value not present in hash if value is not there
    # sunetid/ university id/ ca licence ---- at least one will be there
    seed_hash = {
      cap_profile_id: auth_hash['profileId'],
      active_in_cap:  auth_hash['active'],
      cap_import_enabled: auth_hash['importEnabled']
    }

    Author.add_to_hash_if_present(seed_hash, :sunetid, auth_hash['profile']['uid'])
    Author.add_to_hash_if_present(seed_hash, :university_id, auth_hash['profile']['universityId'])
    Author.add_to_hash_if_present(seed_hash, :email, auth_hash['profile']['email'])
    Author.add_to_hash_if_present(seed_hash, :emails_for_harvest, auth_hash['profile']['email'])
    Author.add_to_hash_if_present(seed_hash, :official_first_name, auth_hash['profile']['names']['legal']['firstName'])
    Author.add_to_hash_if_present(seed_hash, :official_middle_name, auth_hash['profile']['names']['legal']['middleName'])
    Author.add_to_hash_if_present(seed_hash, :official_last_name, auth_hash['profile']['names']['legal']['lastName'])
    Author.add_to_hash_if_present(seed_hash, :cap_first_name, auth_hash['profile']['names']['preferred']['firstName'])
    Author.add_to_hash_if_present(seed_hash, :cap_middle_name, auth_hash['profile']['names']['preferred']['middleName'])
    Author.add_to_hash_if_present(seed_hash, :cap_last_name, auth_hash['profile']['names']['preferred']['lastName'])
    Author.add_to_hash_if_present(seed_hash, :preferred_first_name, auth_hash['profile']['names']['preferred']['firstName'])
    Author.add_to_hash_if_present(seed_hash, :preferred_middle_name, auth_hash['profile']['names']['preferred']['middleName'])
    Author.add_to_hash_if_present(seed_hash, :preferred_last_name, auth_hash['profile']['names']['preferred']['lastName'])
    Author.add_to_hash_if_present(seed_hash, :california_physician_license, auth_hash['profile']['californiaPhysicianLicense'])

    Author.create seed_hash
  end

  def Author.add_to_hash_if_present(seed_hash, key, value)
    if(value.nil?)
      seed_hash[key] = ''
    else
      seed_hash[key] = value
    end
  end

  def Author.fetch_from_cap_and_create(profile_id)
    profile_hash = CapHttpClient.new.get_auth_profile(profile_id)
    Author.create_from_cap_authorship_profile_hash(profile_hash)
  end

end
