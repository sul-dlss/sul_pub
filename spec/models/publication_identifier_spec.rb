# frozen_string_literal: true

describe PublicationIdentifier do
  subject(:pub_id) { FactoryBot.create(:doi_publication_identifier) }

  let(:doi_type) { pub_id.identifier_type }
  let(:doi_value) { pub_id.identifier_value }
  let(:doi_uri) { pub_id.identifier_uri }

  describe '#identifier_type' do
    it 'works' do
      expect(pub_id).to respond_to(:identifier_type)
    end
  end

  describe '#identifier_value' do
    it 'works' do
      expect(pub_id).to respond_to(:identifier_value)
    end
  end

  describe '#identifier_uri' do
    it 'works' do
      expect(pub_id).to respond_to(:identifier_uri)
    end
  end

  describe '#identifier' do
    # the doi factory has all of these attributes

    it 'works' do
      expect(pub_id.identifier).to be_an Hash
    end

    it 'might have :type String' do
      expect(pub_id.identifier[:type]).to be_an String
    end

    it 'might have :id String' do
      expect(pub_id.identifier[:id]).to be_an String
    end

    it 'might have :url String' do
      expect(pub_id.identifier[:url]).to be_an String
    end
  end

  shared_examples 'updates_pub_hash' do
    it 'updates the identifier data in the pubhash' do
      pub_id.pub_hash_update(delete: false)
      ids = pub_id.publication.pub_hash[:identifier]
      expect(ids).to include(type: doi_type, id: doi_value, url: doi_uri)
    end
  end

  shared_examples 'deletes_pub_hash' do
    it 'deletes the identifier data in the pubhash' do
      pub_id.pub_hash_update(delete: true)
      types = pub_id.publication.pub_hash[:identifier].pluck(:type)
      expect(types).not_to include(doi_type)
    end
  end

  describe '#pub_hash_update' do
    context 'when pub_hash[:identifier] does not contain identifier' do
      before do
        pub_id.publication.pub_hash = { identifier: [] }
        pub_id.publication.save!
      end

      it 'pub_hash has no identifiers' do
        # double check that the publication.save! callbacks did not mess up the mock
        expect(pub_id.publication.pub_hash[:identifier]).to be_empty
      end

      it_behaves_like 'deletes_pub_hash'
      it_behaves_like 'updates_pub_hash'
    end

    context 'when pub_hash[:identifier] contains identifier' do
      before do
        pub_id.publication.pub_hash = { identifier: [{ type: 'doi' }] }
        pub_id.publication.save!
      end

      it 'pub_hash has a DOI identifier' do
        # double check that the publication.save! callbacks did not mess up the mock
        expect(pub_id.publication.pub_hash[:identifier]).to include(type: 'doi')
      end

      it_behaves_like 'deletes_pub_hash'
      it_behaves_like 'updates_pub_hash'
    end
  end
end
