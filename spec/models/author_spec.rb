require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Author do
  let(:auth_hash) do
    JSON.parse(File.open('fixtures/cap_poll_author_3810.json', 'r').read)
  end

  let(:missing_fields) do
    JSON.parse(File.open('fixtures/cap_poll_author_3810_missing.json', 'r').read)
  end

  describe '#first_name' do
    it 'is the preferred_first_name' do
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash(auth_hash)
      expect(auth.first_name).to eq(auth.preferred_first_name)
    end
  end

  describe '#middle_name' do
    it 'is the preferred_middle_name' do
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash(auth_hash)
      expect(auth.middle_name).to eq(auth.preferred_middle_name)
    end
  end

  describe '#last_name' do
    it 'is the preferred_last_name' do
      auth = Author.new
      auth.update_from_cap_authorship_profile_hash(auth_hash)
      expect(auth.last_name).to eq(auth.preferred_last_name)
    end
  end

  describe '#institution' do
    it 'is a default institution name provided by Settings' do
      default_institution_name = Settings.HARVESTER.INSTITUTION.name
      auth = Author.new
      expect(auth.institution).to eq(default_institution_name)
    end
  end

  describe '#start_date' do
    it 'is nil (until CAP provides data)' do
      auth = Author.new
      expect(auth.start_date).to be_nil
    end
  end

  describe '#end_date' do
    it 'is nil (until CAP provides data)' do
      auth = Author.new
      expect(auth.end_date).to be_nil

  describe '#approved_sciencewire_ids' do
    let(:pub_without_swid) do
      # The publication is defined in /spec/factories/publication.rb
      # The contributions are are defined in /spec/factories/contribution.rb
      pub = create :publication_with_contributions, contributions_count: 1
      pub.sciencewire_id = nil
      # FactoryGirl knows nothing about the Publication.pub_hash sync issue, so
      # it must be forced to update that data with the contributions.
      pub.pubhash_needs_update!
      pub.save # to update the pub.pub_hash
      pub
    end

    let(:pub_with_swid) do
      pub = pub_without_swid
      pub.sciencewire_id = '9999'
      pub.save
      pub
    end

    let(:contrib_with_swid_unknown) do
      expect(pub_with_swid.contributions.count).to eq 1
      contrib = pub_with_swid.contributions.first
      contrib.status = 'unknown'
      contrib.save
      contrib
    end

    let(:contrib_with_swid_approved) do
      expect(pub_with_swid.contributions.count).to eq 1
      contrib = pub_with_swid.contributions.first
      contrib.status = 'approved'
      contrib.save
      contrib
    end

    let(:contrib_without_swid_approved) do
      expect(pub_without_swid.contributions.count).to eq 1
      contrib = pub_without_swid.contributions.first
      contrib.status = 'approved'
      contrib.save
      contrib
    end

    it 'is empty when there are no publications' do
      expect(subject.publications).to be_empty
      expect(subject.approved_sciencewire_ids).to be_an(Array)
      expect(subject.approved_sciencewire_ids).to be_empty
    end
    it 'is empty when there are no publications with a sciencewire_id' do
      # An approved contribution, cannot generate any
      # SW-seeds without a sciencewire_id.
      author = contrib_without_swid_approved.author
      expect(author.approved_sciencewire_ids).to be_an(Array)
      expect(author.approved_sciencewire_ids).to be_empty
    end
    it 'is empty when there are no approved publications' do
      # Even if a publication has a sciencewire_id, it cannot be
      # in the SW-seeds without being approved.
      author = contrib_with_swid_unknown.author
      expect(author.approved_sciencewire_ids).to be_an(Array)
      expect(author.approved_sciencewire_ids).to be_empty
    end
    it 'is an Array<Integer> when there are approved ScienceWire publications' do
      author = contrib_with_swid_approved.author
      expect(author.approved_sciencewire_ids).to be_an(Array)
      expect(author.approved_sciencewire_ids).not_to be_empty
      expect(author.approved_sciencewire_ids.first).to be_an(Integer)
    end
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
