# frozen_string_literal: true

describe Author do
  subject { create(:author) }

  let(:auth_hash) do
    JSON.parse(File.read('fixtures/cap_poll_author_3810.json'))
  end

  let(:missing_fields) do
    JSON.parse(File.read('fixtures/cap_poll_author_3810_missing.json'))
  end

  describe '#cap_profile_id' do
    it 'validates uniqueness' do
      described_class.find_or_create_by!(cap_profile_id: 1)
      expect { described_class.create!(cap_profile_id: 1) }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'validates presence' do
      expect { described_class.create!(cap_profile_id: '') }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe '#orcidid' do
    it 'indicates if orcidid is valid' do
      # missing url
      expect { described_class.create!(cap_profile_id: '5555', orcidid: '0000-1234-5678-9012') }.to raise_error ActiveRecord::RecordInvalid
      # bad url protocol
      expect { described_class.create!(cap_profile_id: '5555', orcidid: 'http://orcid.org/0000-1234-5678-9012') }.to raise_error ActiveRecord::RecordInvalid
      # invalid url
      expect do
        described_class.create!(cap_profile_id: '5555', orcidid: 'https://test.orcid.org/0000-1234-5678-9012')
      end.to raise_error ActiveRecord::RecordInvalid
      # wrong length
      expect do
        described_class.create!(cap_profile_id: '5555', orcidid: 'https://orcid.org/0000-1234-5678-9012-1234')
      end.to raise_error ActiveRecord::RecordInvalid
      # invalid last digit
      expect { described_class.create!(cap_profile_id: '5555', orcidid: 'https://orcid.org/0000-1234-5678-901A') }.to raise_error ActiveRecord::RecordInvalid
      # missing dashes
      expect { described_class.create!(cap_profile_id: '5555', orcidid: 'https://orcid.org/000012345678901A') }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'saves a valid orcidid' do
      expect do
        described_class.create!(cap_profile_id: '5555', orcidid: 'https://orcid.org/0000-1234-5678-901X')
      end.not_to raise_error ActiveRecord::RecordInvalid
      expect do
        described_class.create!(cap_profile_id: '5556', orcidid: 'https://sandbox.orcid.org/0000-1234-5678-9011')
      end.not_to raise_error ActiveRecord::RecordInvalid
    end

    it 'allows nil orcidid' do
      expect { described_class.create!(cap_profile_id: '5555', orcidid: nil) }.not_to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe '#should_harvest?' do
    it 'indicates if the primary author information changes but not the number of identities' do
      expect(subject.should_harvest?).to be false
      subject.preferred_first_name = "#{subject.first_name}XXX"
      expect(subject.alt_identities_changed).to be_nil
      expect(subject.harvested).to be_nil
      expect(subject.should_harvest?).to be true
    end
  end

  describe '#first_name' do
    it 'is the preferred_first_name' do
      subject.update_from_cap_authorship_profile_hash(auth_hash)
      expect(subject.first_name).to eq(subject.preferred_first_name)
    end
  end

  describe '#middle_name' do
    it 'is the preferred_middle_name' do
      subject.update_from_cap_authorship_profile_hash(auth_hash)
      expect(subject.middle_name).to eq(subject.preferred_middle_name)
    end
  end

  describe '#last_name' do
    it 'is the preferred_last_name' do
      subject.update_from_cap_authorship_profile_hash(auth_hash)
      expect(subject.last_name).to eq(subject.preferred_last_name)
    end
  end

  describe '#institution' do
    it 'is a default institution name provided by Settings' do
      default_institution_name = Settings.HARVESTER.INSTITUTION.name
      expect(subject.institution).to eq(default_institution_name)
    end
  end

  describe '.update_from_cap_authorship_profile_hash' do
    it 'creates an author from the profile JSON returned from the CAP authorship API' do
      subject.update_from_cap_authorship_profile_hash(auth_hash)
      expect(subject.cap_profile_id).to eq(auth_hash['profileId'])
      expect(subject.cap_last_name).to eq(auth_hash['profile']['names']['preferred']['lastName'])
      expect(subject.sunetid).to eq(auth_hash['profile']['uid'])
      expect(subject.cap_visibility).to eq(auth_hash['visibility'])
      # ...
    end

    it 'creates an author from a hash with missing fields' do
      subject.update_from_cap_authorship_profile_hash(missing_fields)
      expect(subject.email).to be_blank
      expect(subject.preferred_middle_name).to be_blank
      expect(subject.emails_for_harvest).to be_blank
    end

    it 'duplicates data' do # TODO: why we don't know?
      subject.update_from_cap_authorship_profile_hash(auth_hash)
      expect(subject.emails_for_harvest).to eq(subject.email)
      expect(subject.preferred_first_name).to eq(subject.cap_first_name)
      expect(subject.preferred_middle_name).to eq(subject.cap_middle_name)
      expect(subject.preferred_last_name).to eq(subject.cap_last_name)
    end
  end

  describe '.fetch_from_cap_and_create' do
    it 'creates an author from the passed in cap profile id' do
      skip 'Administrative Systems firewall rules only allow IP-based requests'
      VCR.use_cassette('author_spec_fetch_from_cap_and_create') do
        author = described_class.fetch_from_cap_and_create 3871
        expect(author.cap_last_name).to eq('Kwon')
      end
    end
  end

  describe '#harvestable?' do
    it 'returns true when the author is active and is import_enabled' do
      h = auth_hash
      h['active'] = true
      h['importEnabled'] = true
      subject.update_from_cap_authorship_profile_hash h
      expect(subject).to be_harvestable
    end

    it 'returns false when the author is not active or not import_enabled' do
      subject.update_from_cap_authorship_profile_hash auth_hash
      expect(subject).not_to be_harvestable
    end
  end

  describe '#assign_pub' do
    let(:pub) { create(:publication_without_author) }

    it 'creates contrib and updates pubhash' do
      expect(subject.publications.count).to eq(0)
      expect(subject.contributions.count).to eq(0)
      expect(Publication.find(pub.id).pub_hash[:authorship].length).to eq(0)

      subject.assign_pub(pub)
      expect(subject.publications.count).to eq(1)
      expect(subject.contributions.count).to eq(1)

      # Verify that author added to publication
      # See https://github.com/sul-dlss/sul_pub/issues/1052
      expect(Publication.find(pub.id).pub_hash[:authorship].length).to eq(1)
    end

    it 'does not create contrib or save publication when not needed' do
      # assign a pub, expect the pub to save as it updates
      expect(pub).to receive(:save!)
      subject.assign_pub(pub)
      expect(subject.contributions.count).to eq(1)
      # assign the pub again, but this time the pub should not save/change!
      expect(pub).not_to receive(:save!)
      subject.assign_pub(pub)
      expect(subject.contributions.count).to eq(1)
    end

    it 'does not attempt to assign a blank publication and does not throw an exception' do
      expect(subject.publications.count).to eq(0)
      expect(subject.contributions.count).to eq(0)

      subject.assign_pub(nil)

      expect(subject.publications.count).to eq(0)
      expect(subject.contributions.count).to eq(0)
    end
  end

  describe '#cap_visibility=' do
    before { auth_hash['visibility'] = 'translucent' }

    it 'validates that cap_visibility is set to a valid value' do
      subject.update_from_cap_authorship_profile_hash(auth_hash)
      expect(subject).to be_invalid
      expect(subject.errors[:cap_visibility]).to eq ['is not included in the list']
    end
  end
end
