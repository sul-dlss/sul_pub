
describe Agent::AuthorName do
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
    context 'when no names are present' do
      it 'returns an empty String' do
        expect(no_names.full_name).to eq ''
      end
    end
    context 'when all names are present' do
      it 'returns the Lastname,Firstname,Middlename' do
        name = "#{all_names.last_name},#{all_names.first_name},#{all_names.middle_name}"
        expect(all_names.full_name).to eq name
      end
    end
  end

  describe '#text_search_query' do
    context 'when no names are present' do
      it 'returns an empty String' do
        skip 'conflicts with publication_query_by_author_name_spec.rb:37'
        expect(no_names.text_search_query).to eq ''
      end
    end
    context 'when all names are present' do
      # additional specs are in publication_query_by_author_name_spec.rb
      it 'is not empty' do
        expect(all_names.text_search_query).not_to be_empty
      end
      it 'includes first_name_query' do
        names = all_names.send(:first_name_query).join(' or ')
        expect(all_names.text_search_query).to include names
      end
      it 'includes middle_name_query' do
        names = all_names.send(:middle_name_query).join(' or ')
        expect(all_names.text_search_query).to include names
      end
    end
  end

  describe '#first_name_query' do
    context 'when no names are present' do
      it 'returns an empty String' do
        expect(no_names.send(:first_name_query)).to eq ''
      end
    end
    context 'when all names are present' do
      let(:fn_query) { all_names.send(:first_name_query) }
      it 'is not empty' do
        expect(fn_query).not_to be_empty
      end
      it 'is Array<String>' do
        expect(fn_query).to be_an Array
        expect(fn_query.first).to be_an String
      end
      it 'includes name with first_name' do
        name = "\"#{all_names.last_name},#{all_names.first_name}\""
        expect(fn_query).to include name
      end
      it 'includes name with first_initial' do
        name = "\"#{all_names.last_name},#{all_names.first_initial}\""
        expect(fn_query).to include name
      end
      it 'does not include name with middle_name' do
        name = "\"#{all_names.last_name},#{all_names.first_name},#{all_names.middle_name}\""
        expect(fn_query).not_to include name
        incl_mn = fn_query.any? { |n| n.include? ",#{all_names.middle_name}" }
        expect(incl_mn).to be false
      end
      it 'does not include name with middle_initial' do
        name = "\"#{all_names.last_name},#{all_names.first_name},#{all_names.middle_initial}\""
        expect(fn_query).not_to include name
        incl_mn = fn_query.any? { |n| n.include? ",#{all_names.middle_initial}" }
        expect(incl_mn).to be false
      end
    end
  end

  describe '#middle_name_query' do
    context 'when no names are present' do
      it 'returns an empty String' do
        expect(no_names.send(:middle_name_query)).to eq ''
      end
    end
    context 'when all names are present' do
      let(:mn_query) { all_names.send(:middle_name_query) }
      it 'is not empty' do
        expect(mn_query).not_to be_empty
      end
      it 'is Array<String>' do
        expect(mn_query).to be_an Array
        expect(mn_query.first).to be_an String
      end
      it 'includes name with middle_name' do
        name = "\"#{all_names.last_name},#{all_names.first_name},#{all_names.middle_name}\""
        expect(mn_query).to include name
      end
      it 'includes name with middle_initial' do
        name = "\"#{all_names.last_name},#{all_names.first_name},#{all_names.middle_initial}\""
        expect(mn_query).to include name
      end
      it 'does not include last_name,first_name' do
        name = "\"#{all_names.last_name},#{all_names.first_name}\""
        expect(mn_query).not_to include name
      end
      it 'does not include last_name,first_initial' do
        name = "\"#{all_names.last_name},#{all_names.first_initial}\""
        expect(mn_query).not_to include name
      end
      it 'includes name with middle_initial appended to first initial' do
        name = "\"#{all_names.last_name},#{all_names.first_initial}#{all_names.middle_initial}\""
        expect(mn_query).to include name
      end
    end
  end

  describe '#==' do
    it 'returns false when names are not the same' do
      expect(no_names == all_names).to be false
    end
    it 'returns true when names are the same' do
      namesA = described_class.new
      namesB = described_class.new
      expect(namesA == namesB).to be true
      namesA = described_class.new(ln, fn, mn)
      namesB = described_class.new(ln, fn, mn)
      expect(namesA == namesB).to be true
    end
  end
end
