require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Author do
  let(:auth_hash) do
    JSON.parse(File.open('fixtures/cap_poll_author_3810.json', 'r').read)
  end

  let(:missing_fields) do
    JSON.parse(File.open('fixtures/cap_poll_author_3810_missing.json', 'r').read)
  end

  describe '.update_from_cap_authorship_profile_hash' do
    it 'creates an author from the profile JSON returned from the CAP authorship API' do
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash(auth_hash)
      expect(auth.cap_profile_id).to eq(auth_hash['profileId'])
      expect(auth.cap_last_name).to eq(auth_hash['profile']['names']['preferred']['lastName'])
      expect(auth.sunetid).to eq(auth_hash['profile']['uid'])
      # ...
    end

    it 'creates an author from a hash with missing fields' do
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash(missing_fields)
      expect(auth.email).to be_blank
      expect(auth.preferred_middle_name).to be_blank
      expect(auth.emails_for_harvest).to be_blank
    end

    it 'duplicates data' do # TODO: why we don't know?
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash(auth_hash)
      expect(auth.emails_for_harvest).to eq(auth.email)
      expect(auth.preferred_first_name).to eq(auth.cap_first_name)
      expect(auth.preferred_middle_name).to eq(auth.cap_middle_name)
      expect(auth.preferred_last_name).to eq(auth.cap_last_name)
    end
  end

  describe '.fetch_from_cap_and_create' do
    it 'creates an author from the passed in cap profile id' do
      skip 'Administrative Systems firewall rules only allow IP-based requests'
      VCR.use_cassette('author_spec_fetch_from_cap_and_create') do
        auth = Author.fetch_from_cap_and_create 3871
        expect(auth.cap_last_name).to eq('Kwon')
      end
    end
  end

  describe '#harvestable?' do
    it 'returns true when the author is active and is import_enabled' do
      h = auth_hash
      h['active'] = true
      h['importEnabled'] = true
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash h
      expect(auth).to be_harvestable
    end

    it 'returns false when the author is not active or not import_enabled' do
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash auth_hash
      expect(auth).not_to be_harvestable
    end
  end
end
