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
    it 'has an authors' do
      expect(pub_hash[:author]).not_to be_nil
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
    end
    it_behaves_like 'pub_hash'
  end

  context 'MEDLINE records' do
    let(:pub_hash_class) { described_class.new(medline_record) }
    let(:pub_hash) { pub_hash_class.pub_hash }

    it 'works with MEDLINE records' do
      expect(pub_hash_class).to be_an described_class
    end
    it_behaves_like 'pub_hash'
    it_behaves_like 'contains_author_data'
  end
end
