# frozen_string_literal: true

describe Agent::AuthorAddress do
  let(:line1) { 'Stanford University' }
  let(:line2) { '' }
  let(:city) { 'Stanford' }
  let(:state) { 'CA' }
  let(:country) { 'USA' }
  let(:full_address) do
    described_class.new(
      line1: line1,
      line2: line2,
      city: city,
      state: state,
      country: country
    )
  end
  let(:empty_address) { described_class.new }

  describe '#initialize' do
    it 'casts params to strings' do
      expect(empty_address.line1).to be_an String
      expect(empty_address.line2).to be_an String
      expect(empty_address.city).to be_an String
      expect(empty_address.state).to be_an String
      expect(empty_address.country).to be_an String
    end
  end

  describe '#empty?' do
    it 'returns true for an empty address' do
      expect(empty_address.to_xml).to be_empty
      expect(empty_address).to receive(:to_xml).and_call_original
      expect(empty_address).to be_empty
    end

    it 'returns false for an address' do
      expect(full_address).to receive(:to_xml).and_call_original
      expect(full_address).not_to be_empty
    end
  end

  describe '#line1' do
    context 'when not present' do
      it 'returns an empty String' do
        expect(empty_address.line1).to eq ''
      end
    end

    context 'when present' do
      it 'returns a String value' do
        expect(full_address.line1).to eq line1
      end
    end
  end

  describe '#line2' do
    context 'when not present' do
      it 'returns an empty String' do
        expect(empty_address.line2).to eq ''
      end
    end

    context 'when present' do
      it 'returns a String value' do
        expect(full_address.line2).to eq line2
      end
    end
  end

  describe '#city' do
    context 'when not present' do
      it 'returns an empty String' do
        expect(empty_address.city).to eq ''
      end
    end

    context 'when present' do
      it 'returns a String value' do
        expect(full_address.city).to eq city
      end
    end
  end

  describe '#state' do
    context 'when not present' do
      it 'returns an empty String' do
        expect(empty_address.state).to eq ''
      end
    end

    context 'when present' do
      it 'returns a String value' do
        expect(full_address.state).to eq state
      end
    end
  end

  describe '#country' do
    context 'when not present' do
      it 'returns an empty String' do
        expect(empty_address.country).to eq ''
      end
    end

    context 'when present' do
      it 'returns a String value' do
        expect(full_address.country).to eq country
      end
    end
  end

  describe '#==' do
    it 'returns false when addresses differ' do
      expect(full_address == empty_address).to be false
    end

    it 'returns true when addresses are the same' do
      other_address = full_address.dup
      expect(full_address == other_address).to be true
    end
  end

  describe '#to_xml' do
    it 'returns a String' do
      expect(full_address.to_xml).to be_an String
    end

    it 'contains a <AddressLine1> when line1 is defined' do
      expect(full_address.to_xml).to include("<AddressLine1>#{line1}</AddressLine1>")
    end

    it 'ommits an <AddressLine2> when line2 is empty' do
      expect(full_address.to_xml).not_to include("<AddressLine2>#{line2}</AddressLine2>")
    end

    it 'contains a <City> when city is defined' do
      expect(full_address.to_xml).to include("<City>#{city}</City>")
    end

    it 'contains a <State> when state is defined' do
      expect(full_address.to_xml).to include("<State>#{state}</State>")
    end

    it 'contains a <Country> when country is defined' do
      expect(full_address.to_xml).to include("<Country>#{country}</Country>")
    end
  end
end
