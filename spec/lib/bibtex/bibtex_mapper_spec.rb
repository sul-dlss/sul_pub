describe BibtexMapper do
  subject(:mapper) { described_class.new(record) }

  let(:records) { BibTeX.open('spec/fixtures/bibtex/publications.bib') }
  let(:article) { records['@article'].first }
  let(:book) { records['@book'].first }
  let(:chapter) { records['@inbook'].first }
  let(:proceedings) { records['@proceedings'].first }

  describe '.authors_to_csl' do
    let(:record) { article }

    it 'works' do
      result = described_class.authors_to_csl(mapper.pub_hash)
      expect(result).not_to be_nil
    end
  end

  describe '.editors_to_csl' do
    let(:record) { chapter }

    it 'works' do
      result = described_class.editors_to_csl(mapper.pub_hash)
      expect(result).not_to be_nil
    end
  end

  describe '#sul_document_type' do
    it 'identifies articles' do
      expect(described_class.new(article).sul_document_type).to eq 'article'
    end
    it 'identifies books' do
      expect(described_class.new(book).sul_document_type).to eq 'book'
    end
    it 'identifies chapters in books' do
      expect(described_class.new(chapter).sul_document_type).to eq 'book'
    end
    it 'identifies proceedings' do
      expect(described_class.new(proceedings).sul_document_type).to eq 'inproceedings'
    end
  end
end
