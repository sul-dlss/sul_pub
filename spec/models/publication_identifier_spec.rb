describe PublicationIdentifier do
  subject(:pub_id) { FactoryGirl.create(:doi_publication_identifier) }

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
end
