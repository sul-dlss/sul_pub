describe Agent::AuthorName do
  let(:fn) { 'Amasa' }
  let(:mn) { 'Leland' }
  let(:ln) { 'Stanford' }
  let(:all_names) { described_class.new(ln, fn, mn) }
  let(:no_names) { described_class.new(nil, nil, nil) }
  let(:no_middle_name) { described_class.new(ln, fn, '') }

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

  describe '#text_search_query' do
    context 'when all names are present' do
      # additional SW specs are in publication_query_by_author_name_spec.rb
      it 'includes appropriate name elements' do
        expect(all_names.text_search_query).to eq "\"Stanford,Amasa,Leland\" or \"Stanford,Amasa,L\""
      end
    end
  end

  describe '#text_search_terms' do
    it 'includes name_query elements' do
      fnames = all_names.send(:name_query)
      expect(all_names.text_search_terms).to include(*fnames)
    end
  end

  describe '#name_query' do
    it 'when no names are present returns an empty String' do
      expect(no_names.send(:name_query)).to eq ''
    end
    context 'when all names are present' do
      let(:fn_query) { all_names.send(:name_query) }
      before do
        allow(Settings.HARVESTER).to receive(:USE_FIRST_INITIAL).and_return(false)
      end
      it 'is Array<String> with non-empty unique values' do
        expect(fn_query).to be_an Array
        expect(fn_query).to all(be_a(String))
        expect(fn_query).not_to include(be_empty)
        expect(fn_query.size).to eq(fn_query.uniq.size)
      end
      it 'does not include only first_name variant (since middle name exists)' do
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_name}"
      end
      it 'excludes name with first_initial when settings do not allow for it' do
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_initial}"
      end
      it 'includes name with middle_name' do
        expect(fn_query).to include "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_name}"
      end
      it 'includes name with middle_initial variant' do
        expect(fn_query).to include "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_initial}"
      end
    end
    context 'when all names are present and settings allow for first initial' do
      before do
        allow(Settings.HARVESTER).to receive(:USE_FIRST_INITIAL).and_return(true)
      end
      let(:fn_query) { all_names.send(:name_query) }
      it 'includes name with first_initial when settings allow for it' do
        expect(fn_query).to include "#{all_names.last_name},#{all_names.first_initial}"
      end
    end

    context 'when middle name not present' do
      let(:fn_query) { no_middle_name.send(:name_query) }
      before do
        allow(Settings.HARVESTER).to receive(:USE_FIRST_INITIAL).and_return(false)
      end
      it 'includes name with first_name' do
        expect(fn_query).to include "#{all_names.last_name},#{all_names.first_name}"
      end
      it 'excludes name with first_initial when settings do not allow for it' do
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_initial}"
      end
      it 'does not include middle_name variants' do
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_name}"
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_name},"
        expect(fn_query).to all(exclude(",#{all_names.middle_name}"))
      end
      it 'does not include middle_initial variants' do
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_initial}"
        expect(fn_query).not_to include "#{all_names.last_name},#{all_names.first_name},"
        expect(fn_query).to all(exclude(",#{all_names.middle_initial}"))
      end
    end
    context 'when middle names not present and settings allow for first initial' do
      before do
        allow(Settings.HARVESTER).to receive(:USE_FIRST_INITIAL).and_return(true)
      end
      let(:fn_query) { no_middle_name.send(:name_query) }
      it 'includes name with first_initial when settings allow for it' do
        expect(fn_query).to include "#{all_names.last_name},#{all_names.first_initial}"
      end
    end
  end

  describe '#==' do
    it 'returns false when names are not the same' do
      expect(no_names).not_to eq all_names
    end
    it 'returns true when names are the same' do
      expect(described_class.new).to eq described_class.new
      expect(described_class.new(ln, fn, mn)).to eq described_class.new(ln, fn, mn)
    end
  end
end
