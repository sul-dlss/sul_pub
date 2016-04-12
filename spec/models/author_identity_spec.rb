require 'spec_helper'

RSpec.describe AuthorIdentity, type: :model do
  subject { FactoryGirl.create :author_identity }

  context 'basics' do
    it 'has working factories' do
      expect(subject).to be_a described_class
      expect(subject.author).to be_a Author
    end

    it 'has Author#alternative_identities' do
      ai = subject.author.alternative_identities
      expect(ai.length).to eq 1
      expect(ai.first).to eq subject
      expect(ai.first.alternate?).to be_truthy
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
    it 'requires first_name' do
      subject.first_name = nil
      expect { subject.save! }.to raise_error ActiveRecord::RecordInvalid
    end
    it 'requires last_name' do
      subject.last_name = nil
      expect { subject.save! }.to raise_error ActiveRecord::RecordInvalid
    end
    it 'requires identity_type' do
      subject.identity_type = nil
      expect { subject.save! }.to raise_error ActiveRecord::RecordInvalid
    end
    it 'requires identity_type to be "alternate"' do
      expect { subject.identity_type = 'foobar' }.to raise_error ArgumentError
      expect { subject.identity_type = 1 }.to raise_error ArgumentError
      expect { subject.identity_type = 'alternate' }.not_to raise_error
      expect { subject.identity_type = :alternate }.not_to raise_error
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
end
