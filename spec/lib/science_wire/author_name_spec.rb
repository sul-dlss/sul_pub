require 'spec_helper'

describe ScienceWire::AuthorName do
  let(:fn) { 'Amasa' }
  let(:mn) { 'Leland' }
  let(:ln) { 'Stanford' }
  let(:all_names) { described_class.new(ln, fn, mn) }
  let(:no_names) { described_class.new(nil, nil, nil) }
  describe '#initialize' do
    it 'casts names to strings' do
      expect(no_names.last).to be_an String
      expect(no_names.first).to be_an String
      expect(no_names.middle).to be_an String
    end
    it 'casts names to strings' do
      expect(all_names.last).to be_an String
      expect(all_names.first).to be_an String
      expect(all_names.middle).to be_an String
    end
  end

  describe '#first_initial' do
    context 'when not present' do
      it 'returns an empty String' do
        expect(no_names.first_initial).to eq ''
      end
    end
    context 'when present' do
      it 'returns the first initial' do
        expect(all_names.first_initial).to eq fn[0].upcase
      end
    end
  end

  describe '#middle_initial' do
    context 'when not present' do
      it 'returns an empty String' do
        expect(no_names.middle_initial).to eq ''
      end
    end
    context 'when present' do
      it 'returns the middle initial' do
        expect(all_names.middle_initial).to eq mn[0].upcase
      end
    end
  end

  describe '#full_name' do
    context 'when no names are present' do
      it 'returns an empty String' do
        expect(no_names.full_name).to eq ''
      end
    end
    context 'when all names are present' do
      it 'returns the Lastname,Firstname,Middlename' do
        expect(all_names.full_name).to eq "#{ln},#{fn},#{mn}"
      end
    end
  end
end
