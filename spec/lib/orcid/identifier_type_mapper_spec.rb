# frozen_string_literal: true

describe Orcid::IdentifierTypeMapper do
  describe '#to_orcid_id_type' do
    it 'maps matching id types' do
      expect(described_class.to_orcid_id_type('pmc')).to eq('pmc')
    end

    it 'maps mismatched id types' do
      expect(described_class.to_orcid_id_type('PMID')).to eq('pmid')
      expect(described_class.to_orcid_id_type('WosUID')).to eq('wosuid')
      expect(described_class.to_orcid_id_type('eissn')).to eq('issn')
    end

    it 'maps missing id types' do
      expect(described_class.to_orcid_id_type('foo')).to be_nil
    end
  end

  describe '#to_sul_pub_id_type' do
    it 'maps matching id types' do
      expect(described_class.to_sul_pub_id_type('pmc')).to eq('pmc')
    end

    it 'maps mismatched id types' do
      expect(described_class.to_sul_pub_id_type('pmid')).to eq('PMID')
      expect(described_class.to_sul_pub_id_type('wosuid')).to eq('WosUID')
    end

    it 'maps missing id types' do
      expect(described_class.to_sul_pub_id_type('foo')).to eq('foo')
    end
  end
end
