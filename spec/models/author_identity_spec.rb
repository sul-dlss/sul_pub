RSpec.describe AuthorIdentity, type: :model do
  subject { FactoryBot.create :author_identity }

  context 'basics' do
    it 'has working factories' do
      expect(subject).to be_a described_class
      expect(subject.author).to be_a Author
    end

    it 'has Author#author_identities' do
      ai = subject.author.author_identities
      expect(ai.length).to eq 1
      expect(ai.first).to eq subject
    end

    it 'has timestamps' do
      expect(subject.created_at).to be_a ActiveSupport::TimeWithZone
      expect(subject.updated_at).to be_a ActiveSupport::TimeWithZone
    end
  end

  context 'validations' do
    it 'requires author' do
      subject.author = nil
      expect { subject.save! }.to raise_error ActiveRecord::RecordInvalid
    end
    it 'sets default first_name' do
      subject.first_name = nil
      expect(subject.save).to be true
      expect(subject.first_name).to eq subject.author.first_name
    end
    it 'requires last_name' do
      subject.last_name = nil
      expect { subject.save! }.to raise_error ActiveRecord::RecordInvalid
    end
    it 'does not require middle_name' do
      subject.middle_name = nil
      expect { subject.save! }.not_to raise_error
    end
    it 'does not require email' do
      subject.email = nil
      expect { subject.save! }.not_to raise_error
    end
    it 'does not require email to match regex' do
      subject.email = 'foobar@example.com'
      expect { subject.save! }.not_to raise_error
      subject.email = 'foobar@example'
      expect { subject.save! }.not_to raise_error
    end
    it 'does not require institution' do
      subject.institution = nil
      expect { subject.save! }.not_to raise_error
    end
    it 'does not require start_date' do
      subject.start_date = nil
      expect { subject.save! }.not_to raise_error
    end
    it 'does not require end_date' do
      subject.end_date = nil
      expect { subject.save! }.not_to raise_error
    end
  end

  context 'relations' do
    let(:author) { subject.author }
    let(:identity_same_as_primary) do
      {
        'firstName'   => author.preferred_first_name,
        'middleName'  => author.preferred_middle_name,
        'lastName'    => author.preferred_last_name,
        'email'       => author.email,
        'institution' => 'Stanford University'
      }
    end
    let(:new_identity1) do
      {
        'firstName'   => 'identity1',
        'lastName'    => 'lastname1',
        'institution' => 'Stanford University'
      }
    end
    let(:new_identity2) do
      {
        'firstName'   => 'identity2',
        'lastName'    => 'lastname2',
        'institution' => 'Stanford University'
      }
    end

    it 'will indicate author is harvestable when number of identities has changed' do
      expect(author.author_identities.length).to eq 1
      author.mirror_author_identities([new_identity1, new_identity2])
      expect(author.author_identities.length).to eq 2
      expect(author.changed?).to be false
      expect(author.harvested).to be false
      expect(author.should_harvest?).to be true
    end

    it 'will indicate author is harvestable if an author identity has changed' do
      expect(author.author_identities.length).to eq 1
      author.mirror_author_identities([new_identity1])
      expect(author.author_identities.length).to eq 1
      expect(author.harvested).to be false
      expect(author.changed?).to be false
      expect(author.should_harvest?).to be true
    end

    it 'will not mirror identities in importSettings identical to primary author info, but will drop the one that is ' \
       'there and count this as a change' do
      expect(author.author_identities.length).to eq 1
      author.mirror_author_identities([identity_same_as_primary]) # must pass in only a single alternate identity for .length == 0
      expect(author.author_identities.length).to eq 0
      expect(author.harvested).to be false
      expect(author.changed?).to be false
      expect(author.should_harvest?).to be true
    end

    it 'will not mirror identical identities in importSettings, *even if* dates are present' do
      author.mirror_author_identities(
        [identity_same_as_primary.merge('startDate' => { 'value' => '2000-01-01' }, 'endDate' => { 'value' => '2010-12-31' })]
      ) # must pass in only a single alternate identity for .length == 0
      expect(author.author_identities.length).to eq 0
    end

    it 'will raise an exception for blanks spaces only in required last name field in importSettings' do
      expect { author.mirror_author_identities([{ 'lastName' => '  ' }]) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'will handle missing required fields (lastName) in importSettings' do
      # FactoryBot creates (at least) 1 Author Identity, so we check for transactionality
      prev = author.author_identities
      expect { author.mirror_author_identities([{ 'lastName' => '' }]) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(author.author_identities).to eq prev
      expect { author.mirror_author_identities([{ 'lastName' => nil }]) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(author.author_identities).to eq prev
      expect(author.mirror_author_identities([{ 'lastName' => author.preferred_last_name }])).to be false # no change, so no update
      expect(author.author_identities).to eq prev
    end

    it 'will not change author_identities if data are missing' do
      author.author_identities.clear # explicitly clear FactoryBot addition(s)
      expect { author.mirror_author_identities([{ 'firstName' => author.preferred_first_name }]) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(author.author_identities.length).to eq 0
    end
  end

  describe '#to_author_attributes' do
    it 'returns an AuthorAttributes object' do
      expect(subject.to_author_attributes).to be_an ScienceWire::AuthorAttributes
    end
    it 'sets the AuthorAttributes name to an Agent::AuthorName from itself' do
      expect(subject.to_author_attributes.name).to eq Agent::AuthorName.new(subject.last_name, subject.first_name, subject.middle_name)
    end
    it 'sets the AuthorAttributes seed_list from itself' do
      expect(subject.to_author_attributes.seed_list).to eq []
    end
    it 'sets the AuthorAttributes email from itself' do
      expect(subject.to_author_attributes.email).to eq subject.email
    end
    it 'sets the AuthorAttributes institution to an Agent::AuthorInstitution from itself' do
      expect(subject.to_author_attributes.institution).to eq Agent::AuthorInstitution.new(subject.institution)
    end
    it 'sets the AuthorAttributes start_date from itself' do
      expect(subject.to_author_attributes.start_date).to eq subject.start_date
    end
    it 'sets the AuthorAttributes end_date from itself' do
      expect(subject.to_author_attributes.end_date).to eq subject.end_date
    end
  end
end
