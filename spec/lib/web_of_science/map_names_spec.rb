describe WebOfScience::MapNames do
  # In this WOS-record, Russ Altman is both an "author" and a "book_editor"
  let(:wos_encoded_xml) { File.read('spec/fixtures/wos_client/wos_record_000386326200035.xml') }
  let(:wos_record) { WebOfScience::Record.new(record: wos_encoded_xml) }

  # anonymous display_name MEDLINE record
  let(:medline_encoded_anon_xml) { File.read('spec/fixtures/wos_client/medline_encoded_record_anon.html') }
  let(:medline_record_anon) { WebOfScience::Record.new(encoded_record: medline_encoded_anon_xml) }

  # Cannot find any MEDLINE records with an "editor" of any kind
  let(:medline_encoded_xml) { File.read('spec/fixtures/wos_client/medline_encoded_record.html') }
  let(:medline_record) { WebOfScience::Record.new(encoded_record: medline_encoded_xml) }

  describe '#new' do
    it 'works with WOS records' do
      result = described_class.new(wos_record)
      expect(result).to be_an described_class
    end
    it 'raises ArgumentError with nil params' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end
    it 'raises ArgumentError with anything other than WebOfScience::Record' do
      expect { described_class.new('could be xml') }.to raise_error(ArgumentError)
    end
  end

  shared_examples 'pub_hash' do
    it 'works' do
      expect(pub_hash).to be_an Hash
    end
  end

  shared_examples 'contains_author_data' do
    it 'has authors with a name key in hash' do
      expect(pub_hash[:author].size).to be > 0
      expect(pub_hash[:author]).to all(match a_hash_including(name: be_present))
    end
    it 'has an authorcount' do
      expect(pub_hash[:authorcount]).not_to be_nil
    end
    it 'can map authors to CSL format' do
      csl_authors = described_class.authors_to_csl(pub_hash[:author])
      expect(csl_authors).to be_an Array
      expect(csl_authors.count).to eq pub_hash[:authorcount]
      expect(csl_authors.first).to include('family' => String, 'given' => String)
    end
    it 'can map editors to CSL format' do
      csl_editors = described_class.editors_to_csl(pub_hash[:author])
      expect(csl_editors).to be_an Array
      editor = csl_editors.first # need to check for .nil? below because MEDLINE has none
      expect(editor).to include('family' => String, 'given' => String) unless editor.nil?
    end
  end

  context 'WOS records' do
    let(:pub_hash_class) { described_class.new(wos_record) }
    let(:pub_hash) { pub_hash_class.pub_hash }

    it 'works with WOS records' do
      expect(pub_hash_class).to be_an described_class
      expect(pub_hash[:author].size).to eq 9
    end
    it 'parses wos names where the first and middle initial are in the first name field and adds the :name variant' do
      name = { first_name: 'John Q.', middle_name: '', last_name: 'Public' }
      expect(pub_hash_class.send(:wos_name, name)).to eq(first_name: 'John', middle_name: 'Q', last_name: 'Public', name: 'Public,John,Q')
    end
    it 'parses wos names where the first and middle initial without a period are in the first name field and adds the :name variant' do
      name = { first_name: 'John Q', middle_name: '', last_name: 'Public' }
      expect(pub_hash_class.send(:wos_name, name)).to eq(first_name: 'John', middle_name: 'Q', last_name: 'Public', name: 'Public,John,Q')
    end
    it 'parses wos names where the first name has multiple words including the middle initial and adds the :name variant' do
      name = { first_name: 'John Quimby Q', middle_name: '', last_name: 'Public' }
      expect(pub_hash_class.send(:wos_name, name)).to eq(first_name: 'John Quimby', middle_name: 'Q', last_name: 'Public', name: 'Public,John Quimby,Q')
    end
    it 'parses wos names where the initial is also in the first name adds the :name variant' do
      name = { first_name: 'Russel R. R.', middle_name: '', last_name: 'Public' }
      expect(pub_hash_class.send(:wos_name, name)).to eq(first_name: 'Russel R.', middle_name: 'R', last_name: 'Public', name: 'Public,Russel R.,R')
    end
    it 'parses wos names where the first name has more than word and adds the :name variant' do
      name = { first_name: 'John Quincy', middle_name: '', last_name: 'Public' }
      expect(pub_hash_class.send(:wos_name, name)).to eq(first_name: 'John Quincy', middle_name: '', last_name: 'Public', name: 'Public,John Quincy,')
    end
    it_behaves_like 'pub_hash'
    it_behaves_like 'contains_author_data'
  end

  context 'MEDLINE records with anonymous names' do
    let(:pub_hash_class) { described_class.new(medline_record_anon) }
    let(:pub_hash) { pub_hash_class.pub_hash }

    it 'works with WOS records with anonymous names' do
      expect(pub_hash[:author]).not_to be_nil
      expect(pub_hash[:authorcount]).to be 0
      csl_authors = described_class.authors_to_csl(pub_hash[:author])
      expect(csl_authors).to eq []
      expect(csl_authors.count).to eq pub_hash[:authorcount]
      expect(pub_hash_class.send(:extract_names, medline_record_anon)).to eq([{ display_name: '[Anonymous]', role: 'anon', last_name: '[Anonymous]', given_name: nil, name: '[Anonymous],,' }])
    end
    it_behaves_like 'pub_hash'
  end

  context 'MEDLINE records' do
    let(:pub_hash_class) { described_class.new(medline_record) }
    let(:pub_hash) { pub_hash_class.pub_hash }

    it 'works with MEDLINE records' do
      expect(pub_hash_class).to be_an described_class
    end
    it 'returns itself if missing the display_name or full_name variants' do
      name = { first_name: 'John', middle_name: 'Q', last_name: 'Public' }
      expect(pub_hash_class.send(:medline_name, name)).to eq name
    end
    it 'parses full_name if display_name missing and adds the :name variant' do
      name = { full_name: 'Public, John Q' }
      expect(pub_hash_class.send(:medline_name, name)).to eq(first_name: 'John', middle_name: 'Q', last_name: 'Public', name: 'Public,John,Q', full_name: 'Public, John Q', given_name: 'John Q')
    end
    it 'parses display_name if full_name missing and adds the :name variant' do
      name = { display_name: 'Public, John Q' }
      expect(pub_hash_class.send(:medline_name, name)).to eq(first_name: 'John', middle_name: 'Q', last_name: 'Public', name: 'Public,John,Q', display_name: 'Public, John Q', given_name: 'John Q')
    end
    it 'parses full_name with just two initials and adds the :name variant' do
      name = { full_name: 'Public, J Q' }
      expect(pub_hash_class.send(:medline_name, name)).to eq(first_name: 'J', middle_name: 'Q', last_name: 'Public', name: 'Public,J,Q', full_name: 'Public, J Q', given_name: 'J Q')
    end
    it_behaves_like 'pub_hash'
    it_behaves_like 'contains_author_data'
  end
end
