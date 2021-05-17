# frozen_string_literal: true

describe Agent::AuthorInstitution do
  describe '#initialize' do
    subject { described_class.new(nil, nil) }

    it 'casts name to String' do
      expect(subject.name).to be_an String
    end

    it 'strips whitespace from name' do
      name = described_class.new('  name  ').name
      expect(name).to be_an String
      expect(name).to eq('name')
    end

    it 'address is optional' do
      expect { described_class.new('name') }.not_to raise_error
    end

    it 'address defaults to an empty Agent::AuthorAddress' do
      address = described_class.new('name').address
      expect(address).to be_an Agent::AuthorAddress
      expect(address).to be_blank
      expect(address).to be_empty
    end
  end

  describe '#normalize_name' do
    context 'when name has excluded words at the beginning of the string' do
      subject { described_class.new('The University of North Carolina') }

      it 'normalizes institution name' do
        expect(subject.normalize_name).to eq 'north carolina'
      end
    end

    context 'when present with removed words throughout the institution string' do
      subject { described_class.new('The Flinders University of South Australia') }

      it 'normalizes institution name' do
        expect(subject.normalize_name).to eq 'flinders south australia'
      end
    end

    context 'when not present' do
      subject { described_class.new(nil) }

      it 'returns empty string' do
        expect(subject.normalize_name).to eq ''
      end
    end
  end
end
