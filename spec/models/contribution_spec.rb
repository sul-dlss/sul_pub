require 'spec_helper'
SingleCov.covered!

describe Contribution do
  ##
  let(:pub_with_contrib) do
    # The publication is defined in /spec/factories/publication.rb
    # The contributions are are defined in /spec/factories/contribution.rb
    pub = create :publication_with_contributions, contributions_count: 1
    # FactoryGirl knows nothing about the Publication.pub_hash sync issue, so
    # it must be forced to update that data with the contributions.
    pub.pubhash_needs_update!
    pub.save # to update the pub.pub_hash
    pub
  end

  let(:authorship_json) do
    # return JSON because this is what the sul-pub API receives
    pub_with_contrib.pub_hash[:authorship].first.to_json
  end

  let(:authorship) do
    # parse the authorship_json because this is what the sul-pub API does
    JSON.parse(authorship_json)
  end

  let(:subject) { pub_with_contrib.contributions.first }

  describe '#cap_profile_id' do
    it 'returns the author.cap_profile_id' do
      expect(subject.cap_profile_id).to eq(subject.author.cap_profile_id)
    end
  end

  describe '#publication' do
    it 'returns a Publication' do
      expect(subject.publication).to be_an Publication
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

  describe '#authorship_valid?' do
    it 'calls #author_valid?' do
      expect(described_class).to receive(:author_valid?)
      described_class.authorship_valid?(authorship)
    end
    it 'calls #all_fields_present?' do
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
      auth = authorship
      auth['cap_profile_id'] = 99
      auth['sul_author_id'] = 99
      expect(described_class.author_valid?(auth)).to be false
    end
    it 'returns false for an authorship hash without an author_id' do
      auth = authorship
      auth['cap_profile_id'] = nil
      auth['sul_author_id'] = nil
      expect(described_class.author_valid?(auth)).to be false
    end
  end

  describe '.valid_fields?' do
    it 'returns true for a valid authorship hash' do
      expect(described_class.valid_fields?(authorship)).to be true
    end
    it 'returns false for an authorship hash without "featured"' do
      auth = authorship
      auth['featured'] = nil
      expect(described_class.valid_fields?(auth)).to be false
    end
    it 'returns false for an authorship hash without "status"' do
      auth = authorship
      auth['status'] = nil
      expect(described_class.valid_fields?(auth)).to be false
    end
    it 'returns false for an authorship hash without "visibility"' do
      auth = authorship
      auth['visibility'] = nil
      expect(described_class.valid_fields?(auth)).to be false
    end
  end

  describe '.featured_valid?' do
    it 'returns true for a valid authorship hash' do
      expect(described_class.featured_valid?(authorship)).to be true
    end
    it 'returns false for an authorship hash without "featured"' do
      auth = authorship
      auth['featured'] = nil
      expect(described_class.featured_valid?(auth)).to be false
    end
  end

  describe '.status_valid?' do
    it 'returns true for a valid authorship hash' do
      expect(described_class.status_valid?(authorship)).to be true
    end
    it 'returns true for an upper case field value' do
      authorship['status'].upcase!
      expect(described_class.status_valid?(authorship)).to be true
    end
    it 'returns false for an authorship hash without "status"' do
      authorship.delete 'status'
      expect(described_class.status_valid?(authorship)).to be false
    end
    it 'returns false for an authorship hash with a nil "status"' do
      authorship['status'] = nil
      expect(described_class.status_valid?(authorship)).to be false
    end
    it 'returns false for an authorship hash with an invalid "status"' do
      authorship['status'] = 'invalid value'
      expect(described_class.status_valid?(authorship)).to be false
    end
  end

  describe '.visibility_valid?' do
    it 'returns true for a valid authorship hash' do
      expect(described_class.visibility_valid?(authorship)).to be true
    end
    it 'returns true for an upper case field value' do
      authorship['visibility'].upcase!
      expect(described_class.visibility_valid?(authorship)).to be true
    end
    it 'returns false for an authorship hash without "visibility"' do
      authorship.delete 'visibility'
      expect(described_class.visibility_valid?(authorship)).to be false
    end
    it 'returns false for an authorship hash with a nil "visibility"' do
      authorship['visibility'] = nil
      expect(described_class.visibility_valid?(authorship)).to be false
    end
    it 'returns false for an authorship hash with an invalid "visibility"' do
      authorship['visibility'] = 'invalid value'
      expect(described_class.visibility_valid?(authorship)).to be false
    end
  end

  describe '.find_or_create_by_author_and_publication' do
    it 'calls find_or_create_by_author_id_and_publication_id' do
      expect(described_class).to receive(:find_or_create_by)
        .with(
          author_id: subject.author.id,
          publication_id: subject.publication.id
        ).and_call_original
      described_class.find_or_create_by_author_and_publication(
        subject.author, subject.publication
      )
    end
    it 'returns an existing contribution' do
      contrib = described_class.find_or_create_by_author_and_publication(
        subject.author, subject.publication
      )
      expect(subject.id).to eq(contrib.id)
    end
  end

  describe '#to_pub_hash' do
    it 'returns a valid authorship hash' do
      auth = authorship.symbolize_keys
      expect(subject.to_pub_hash).to eq(auth)
    end
  end
end
