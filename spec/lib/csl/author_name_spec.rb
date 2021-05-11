describe Csl::AuthorName do
  let(:fn) { 'Amasa' }
  let(:mn) { 'Leland' }
  let(:ln) { 'Stanford' }
  let(:all_names) { described_class.new(firstname: fn, middlename: mn, lastname: ln) }
  let(:no_names) { described_class.new({}) }
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

  describe '#first_name' do
    context 'when not present' do
      it 'returns an empty String' do
        expect(no_names.first_name).to eq ''
      end
    end
    context 'when present' do
      it 'returns the first name' do
        expect(all_names.first_name).to eq fn
      end
    end
    context 'when first is an initial' do
      let(:fn) { 'A' }
      it 'returns the first initial plus period' do
        expect(all_names.first_name).to eq "#{all_names.first_initial}."
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

  describe '#middle_name' do
    context 'when not present' do
      it 'returns an empty String' do
        expect(no_names.middle_name).to eq ''
      end
    end
    context 'when present' do
      it 'returns the middle name' do
        expect(all_names.middle_name).to eq mn
      end
    end
    context 'when middle is an initial' do
      let(:mn) { 'L' }
      it 'returns the middle initial plus period' do
        expect(all_names.middle_name).to eq "#{all_names.middle_initial}."
      end
    end
  end

  describe '#family_name' do
    context 'when no names are present' do
      it 'returns an empty String' do
        expect(no_names.family_name).to eq ''
      end
    end
    context 'when all names are present' do
      it 'returns the last name' do
        expect(all_names.family_name).to eq ln
      end
    end
  end

  describe '#given_name' do
    context 'when no names are present' do
      it 'returns an empty String' do
        expect(no_names.given_name).to eq ''
      end
    end
    context 'when all names are present' do
      it 'returns a combination of the first and middle name' do
        expect(all_names.given_name).to include fn
        expect(all_names.given_name).to include mn
        expect(all_names.given_name).to eq "#{fn} #{mn}".strip
      end
    end
  end

  describe '#to_csl_author' do
    context 'when no names are present' do
      it 'returns a Hash with empty String values' do
        expect(no_names.to_csl_author).to be_an Hash
        csl_author = { 'family' => '', 'given' => '' }
        expect(no_names.to_csl_author).to eq csl_author
      end
    end
    context 'when all names are present' do
      # additional specs are in publication_query_by_author_name_spec.rb
      it 'returns a Hash with family and given names' do
        csl_author = {
          'family' => all_names.family_name,
          'given' => all_names.given_name
        }
        expect(all_names.to_csl_author).to eq csl_author
      end
    end
  end

  describe '#==' do
    context 'when no names are present' do
      it 'returns true when compared with another empty names' do
        other_names = no_names.dup
        expect(no_names == other_names).to be true
      end
      it 'returns false when compared with different names' do
        other_names = described_class.new(lastname: 'Bloggs')
        expect(no_names == other_names).to be false
      end
    end
    context 'when all names are present' do
      it 'returns true when compared with the same names' do
        other_names = all_names.dup
        expect(all_names == other_names).to be true
      end
      it 'returns false when compared with different names' do
        other_names = described_class.new(lastname: 'Bloggs')
        expect(all_names == other_names).to be false
      end
    end
  end
end
