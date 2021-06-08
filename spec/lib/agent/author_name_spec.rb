# frozen_string_literal: true

describe Agent::AuthorName do
  let(:fn) { 'Amasa' }
  let(:mn) { 'Leland' }
  let(:ln) { 'Stanford' }
  let(:all_names) { described_class.new(ln, fn, mn) }
  let(:no_names) { described_class.new(nil, nil, nil) }

  describe '#initialize' do
    it 'casts empty names to strings' do
      expect(no_names.last).to be_a String
      expect(no_names.first).to be_a String
      expect(no_names.middle).to be_a String
    end
  end

  describe '#initial' do
    context 'when not present' do
      it 'returns an empty String' do
        expect(no_names.first_initial).to eq ''
        expect(no_names.middle_initial).to eq ''
      end
    end

    context 'when present' do
      it 'returns the first capital letter' do
        expect(all_names.first_initial).to eq fn.scan(/[[:upper:]]/).first
        expect(all_names.first_initial).to eq 'A'
        expect(all_names.middle_initial).to eq mn.scan(/[[:upper:]]/).first
        expect(all_names.middle_initial).to eq 'L'
      end
    end

    context 'when it contains particles' do
      let(:fn) { 'de-Maria' }
      let(:mn) { 'del-Solano' }

      it 'returns the first capital letter' do
        expect(all_names.first_initial).to eq fn.scan(/[[:upper:]]/).first
        expect(all_names.first_initial).to eq 'M'
        expect(all_names.middle_initial).to eq mn.scan(/[[:upper:]]/).first
        expect(all_names.middle_initial).to eq 'S'
      end
    end
  end

  describe '#proper_name' do
    context 'when name is empty' do
      it 'returns an empty String' do
        expect(no_names).to receive(:proper_name).twice.and_call_original
        expect(no_names.first_name).to eq ''
        expect(no_names.middle_name).to eq ''
      end
    end

    context 'when name is present' do
      it 'returns the name, capitalized' do
        expect(all_names).to receive(:proper_name).twice.and_call_original
        expect(all_names.first_name).to eq 'Amasa'
        expect(all_names.middle_name).to eq 'Leland'
      end
    end

    context 'when it contains particles and capital letters' do
      let(:fn) { 'de-Maria' }
      let(:mn) { 'Da salvador' }

      it 'returns the name, as is' do
        expect(all_names).to receive(:proper_name).twice.and_call_original
        expect(all_names.first_name).to eq fn
        expect(all_names.middle_name).to eq mn
      end
    end

    context 'when it contains particles and no capital letters' do
      let(:fn) { 'del maria' }
      let(:mn) { 'da salvador' }

      it 'returns the name, in a capitalized form' do
        expect(all_names).to receive(:proper_name).twice.and_call_original
        expect(all_names.first_name).to eq 'del Maria'
        expect(all_names.middle_name).to eq 'da Salvador'
      end
    end

    context 'when it contains hyphenated particles and no capital letters' do
      let(:fn) { 'de-maria' }
      let(:mn) { 'el-segundo' }

      it 'returns the name, in a capitalized form' do
        expect(all_names).to receive(:proper_name).twice.and_call_original
        expect(all_names.first_name).to eq 'de-Maria'
        expect(all_names.middle_name).to eq 'el-Segundo'
      end
    end

    context 'when it contains hyphenated names and no capital letters' do
      let(:fn) { 'fred-maguire' }
      let(:mn) { 'john-frederick' }

      it 'returns the name, in a capitalized form' do
        expect(all_names).to receive(:proper_name).twice.and_call_original
        expect(all_names.first_name).to eq 'Fred-Maguire'
        expect(all_names.middle_name).to eq 'John-Frederick'
      end
    end
  end

  describe '#full_name' do
    it 'when no names are present returns an empty String' do
      expect(no_names.full_name).to eq ''
    end

    context 'when all names are present' do
      it 'returns the Lastname,Firstname,Middlename' do
        expect(all_names.full_name).to eq "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_name}"
      end
    end
  end

  describe '#text_search_terms' do
    it 'includes first_name_query and middle_name_query elements when first initial is unique' do
      fnames = all_names.send(:first_name_query, true)
      mnames = all_names.send(:middle_name_query, true)
      expect(fnames.size).to eq 2 # two name variants, full first name plus first initial
      expect(mnames.size).to eq 4 # four name variants, which include middle name and middle initial variants
      expect(all_names.text_search_terms).to include(*fnames, *mnames) # default is to use first initial, this verifies
      expect(all_names.text_search_terms(use_first_initial: true)).to include(*fnames, *mnames)
    end

    it 'includes first_name_query and middle_name_query elements when first initial is not unique' do
      fnames = all_names.send(:first_name_query, false)
      mnames = all_names.send(:middle_name_query, false)
      expect(fnames.size).to eq 1 # only one name variant with only full first name (i.e. no first initial)
      expect(mnames.size).to eq 2 # two name variants, includes full middle name and middle initial
      expect(all_names.text_search_terms(use_first_initial: false)).to include(*fnames, *mnames)
    end
  end

  describe '#first_name_query' do
    it 'when no names are present returns an empty String' do
      expect(no_names.send(:first_name_query, true)).to eq ''
    end

    context 'when all names are present with middle initial' do
      let(:fn_query) { all_names.send(:first_name_query, true) }

      it 'is Array<String> with non-empty unique values' do
        expect(fn_query).to be_an Array
        expect(fn_query).to all(be_a(String))
        expect(fn_query).not_to include(be_empty)
        expect(fn_query.size).to eq(fn_query.uniq.size)
      end

      it 'includes name with first_name' do
        expect(fn_query).to include "#{all_names.last_name},#{all_names.first_name}"
      end

      it 'includes name with first_initial when settings allow for it' do
        expect(fn_query).to include "#{all_names.last_name},#{all_names.first_initial}"
      end

      it 'does not include name with middle_name' do
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_name}"
        expect(fn_query).to all(exclude(",#{all_names.middle_name}"))
      end

      it 'does not include name with middle_initial' do
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_initial}"
        expect(fn_query).to all(exclude(",#{all_names.middle_initial}"))
      end
    end

    context 'when all names are present without middle initial' do
      let(:fn_query) { all_names.send(:first_name_query, false) }

      it 'is Array<String> with non-empty unique values' do
        expect(fn_query).to be_an Array
        expect(fn_query).to all(be_a(String))
        expect(fn_query).not_to include(be_empty)
        expect(fn_query.size).to eq(fn_query.uniq.size)
      end

      it 'includes name with first_name' do
        expect(fn_query).to include "#{all_names.last_name},#{all_names.first_name}"
      end

      it 'does not include name with first_initial' do
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_initial}"
      end

      it 'does not include name with middle_name' do
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_name}"
        expect(fn_query).to all(exclude(",#{all_names.middle_name}"))
      end

      it 'does not include name with middle_initial' do
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_initial}"
        expect(fn_query).to all(exclude(",#{all_names.middle_initial}"))
      end
    end
  end

  describe '#middle_name_query' do
    it 'when no names are present returns an empty String' do
      expect(no_names.send(:middle_name_query, false)).to eq ''
    end

    context 'when all names are present' do
      let(:mn_query) { all_names.send(:middle_name_query, false) }

      it 'is Array<String> with non-empty unique values' do
        expect(mn_query).to be_an Array
        expect(mn_query).to all(be_a(String))
        expect(mn_query).not_to include(be_empty)
        expect(mn_query.size).to eq(mn_query.uniq.size)
      end

      it 'includes name with middle_name' do
        expect(mn_query).to include "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_name}"
      end

      it 'includes name with middle_initial' do
        expect(mn_query).to include "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_initial}"
      end

      it 'does not include last_name,first_name' do
        expect(mn_query).not_to include "#{all_names.last_name},#{all_names.first_name}"
      end

      it 'does not include last_name,first_initial' do
        expect(mn_query).not_to include "#{all_names.last_name},#{all_names.first_initial}"
      end

      it 'excludes name with middle_initial appended to first initial when settings do not allow for it' do
        expect(mn_query).not_to include "#{all_names.last_name},#{all_names.first_initial}#{all_names.middle_initial}"
      end
    end

    context 'when all names are present and settings allow for first initial' do
      let(:mn_query) { all_names.send(:middle_name_query, true) }

      it 'includes name with middle_initial appended to first initial when settings allow for it' do
        expect(mn_query).to include "#{all_names.last_name},#{all_names.first_initial}#{all_names.middle_initial}"
      end
    end
  end

  describe '#==' do
    it 'returns false when names are not the same' do
      expect(no_names).not_to eq all_names
    end

    # rubocop:disable RSpec/IdenticalEqualityAssertion
    it 'returns true when names are the same' do
      expect(described_class.new).to eq described_class.new
      expect(described_class.new(ln, fn, mn)).to eq described_class.new(ln, fn, mn)
    end
    # rubocop:enable RSpec/IdenticalEqualityAssertion
  end
end
