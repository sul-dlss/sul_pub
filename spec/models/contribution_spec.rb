# frozen_string_literal: true

describe Contribution do
  subject { pub_with_contrib.contributions.first }

  let(:pub_with_contrib) do
    # The publication is defined in /spec/factories/publication.rb
    # The contributions are are defined in /spec/factories/contribution.rb
    pub = create :publication_with_contributions, contributions_count: 1
    # FactoryBot knows nothing about the Publication.pub_hash sync issue, so
    # it must be forced to update that data with the contributions.
    pub.pubhash_needs_update!
    pub.save # to update the pub.pub_hash
    pub
  end

  # return JSON because this is what the sul-pub API receives
  let(:authorship_json) { pub_with_contrib.pub_hash[:authorship].first.to_json }
  let(:authorship) { JSON.parse(authorship_json) } # parse authorship_json like sul-pub API

  # used by OK Computer checks, once broken by after_initialize/#init method
  describe '#select' do
    it 'still works' do
      pub_with_contrib
      expect(described_class.select(:id).first!).to be_present
    end
  end

  describe '#cap_profile_id' do
    it 'returns the author.cap_profile_id' do
      expect(subject.cap_profile_id).to eq(subject.author.cap_profile_id)
    end
  end

  describe '#publication' do
    it 'returns a Publication' do
      expect(subject.publication).to be_a Publication
    end
  end

  describe '#author' do
    it 'returns an Author' do
      expect(subject.author).to be_an Author
    end
  end

  # has_one :publication_identifier, -> { where("publication_identifiers.identifier_type = 'PublicationItemId'") },
  #         class_name: 'PublicationIdentifier',
  #         foreign_key: 'publication_id',
  #         primary_key: 'publication_id'
  describe '#publication_identifier' do
    it 'returns a Publication.id' do
      skip 'This is not working as expected with the current mocks - to be fixed'
      expect(subject.publication_identifier).to eq(pub_with_contrib.id)
    end
  end

  context 'ActiveRecord validation' do
    let(:params) do
      { publication_id: pub_with_contrib.id, author_id: subject.author.id, visibility: 'private', status: 'approved' }
    end

    it 'constrains field values' do
      expect { described_class.create!(params) }.not_to raise_error
      expect { described_class.create! }.to raise_error ActiveRecord::RecordInvalid
      expect { described_class.create!(params.merge(visibility: 'bad'))   }.to raise_error ActiveRecord::RecordInvalid
      expect { described_class.create!(params.merge(status: 'illegal'))   }.to raise_error ActiveRecord::RecordInvalid
      expect { described_class.create!(params.merge(author: nil))         }.to raise_error ActiveRecord::RecordInvalid
      expect { described_class.create!(params.merge(publication_id: nil)) }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe '#authorship_valid?' do
    it 'calls #author_valid? and #valid_fields?' do
      expect(described_class).to receive(:author_valid?).and_return(true)
      expect(described_class).to receive(:valid_fields?)
      described_class.authorship_valid?(authorship)
    end
    it 'returns true for a valid authorship hash' do
      expect(described_class.authorship_valid?(authorship)).to be true
    end
  end

  describe '.author_valid?' do
    it 'returns true for a valid authorship hash' do
      expect(described_class.author_valid?(authorship)).to be true
    end
    it 'returns false for an authorship hash with an invalid author' do
      # author factory creates random ids starting at 10,000
      authorship.merge!(cap_profile_id: 99, sul_author_id: 99)
      expect(described_class.author_valid?(authorship)).to be false
    end
    it 'returns false for an authorship hash without an author_id' do
      authorship.merge!(cap_profile_id: nil, sul_author_id: nil)
      expect(described_class.author_valid?(authorship)).to be false
    end
  end

  describe '.valid_fields?' do
    it 'returns true for a valid authorship hash' do
      expect(described_class.valid_fields?(authorship)).to be true
    end
    context 'for invalid authorship hashes' do
      it 'returns false for bad values' do
        expect(described_class.valid_fields?(authorship.merge(status: 'XYZ'))).to be false
        expect(described_class.valid_fields?(authorship.merge(visibility: 'transparent'))).to be false
      end
      it 'returns false without "featured"' do
        authorship['featured'] = nil
        expect(described_class.valid_fields?(authorship)).to be false
      end
      it 'returns false without "status"' do
        authorship['status'] = nil
        expect(described_class.valid_fields?(authorship)).to be false
      end
      it 'returns false without "visibility"' do
        authorship['visibility'] = nil
        expect(described_class.valid_fields?(authorship)).to be false
      end
    end
  end

  describe '#to_pub_hash' do
    it 'returns a valid authorship hash' do
      auth = authorship.symbolize_keys
      expect(subject.to_pub_hash).to eq(auth)
    end
  end
end
