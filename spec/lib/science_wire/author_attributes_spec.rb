require 'spec_helper'

describe ScienceWire::AuthorAttributes do
  describe '#initialize' do
    subject { described_class.new(nil, nil, [], 0, []) }
    it 'casts names and email to strings' do
      expect(subject.last_name).to be_an String
      expect(subject.first_name).to be_an String
      expect(subject.middle_name).to be_an String
      expect(subject.email).to be_an String
    end
  end
  describe '#first_name_initial' do
    context 'when not present' do
      subject { described_class.new(nil, nil, [], 0, []) }
      it 'returns the first initial' do
        expect(subject.first_name_initial).to eq ''
      end
    end
    context 'when present' do
      subject { described_class.new(nil, 'Leland', [], 0, []) }
      it 'returns the first initial' do
        expect(subject.first_name_initial).to eq 'L'
      end
    end
  end
end
