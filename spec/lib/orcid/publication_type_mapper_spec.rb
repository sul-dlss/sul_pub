# frozen_string_literal: true

describe Orcid::PublicationTypeMapper do
  describe '#to_work_type' do
    it 'maps matching id types' do
      expect(described_class.to_work_type('article')).to eq('journal-article')
    end

    it 'maps missing id types' do
      expect(described_class.to_work_type('foo')).to be_nil
    end
  end

  describe '#to_pub_type' do
    it 'maps matching id types' do
      expect(described_class.to_pub_type('journal-article')).to eq('article')
    end

    it 'maps missing id types' do
      expect(described_class.to_pub_type('foo')).to be_nil
    end
  end

  describe '#work_type?' do
    it 'is true if valid' do
      expect(described_class.work_type?('journal-article')).to be true
    end

    it 'is false if valid' do
      expect(described_class.work_type?('foo')).to be false
    end
  end
end
