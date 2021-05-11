describe BibtexIdentifiers do
  subject(:identifiers) { described_class.new record }

  let(:records) { BibTeX.open('spec/fixtures/bibtex/publications.bib') }
  let(:record) { records['@proceedings'].first }

  it 'works' do
    expect(identifiers).to be_an described_class
  end
  it 'raises ArgumentError with nil params' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  shared_examples 'identifier_accessors' do
    # when ids['x'] is nil, the expectation is that it should be nil
    it 'doi' do
      expect(identifiers.doi).to eq(ids['doi'])
    end
    it 'doi_uri' do
      expect(identifiers.doi_uri).to eq(ids['doi_uri'])
    end
    it 'isbn' do
      expect(identifiers.isbn).to eq(ids['isbn'])
    end
    it 'isbn_uri' do
      expect(identifiers.isbn_uri).to eq(ids['isbn_uri'])
    end
    it 'issn' do
      expect(identifiers.issn).to eq(ids['issn'])
    end
    it 'issn_uri' do
      expect(identifiers.issn_uri).to eq(ids['issn_uri'])
    end
    it 'pmid' do
      expect(identifiers.pmid).to eq(ids['pmid'])
    end
    it 'pmid_uri' do
      expect(identifiers.pmid_uri).to eq(ids['pmid_uri'])
    end
  end

  shared_examples 'to_h' do
    let(:hash) { identifiers.to_h }

    it 'works' do
      expect(hash).to be_an Hash
    end
    it 'contains identifiers' do
      expect(hash).to eq ids.compact
    end
    it 'is mutable and accepts anything' do
      hash.update(a: 1)
      expect(hash).to include(a: 1)
    end
  end

  shared_examples 'pub_hash' do
    let(:pub_hash) { identifiers.pub_hash }

    it 'is an Array' do
      expect(pub_hash).to be_an Array
    end
    it 'has Hash elements' do
      expect(pub_hash.first).to be_an Hash
    end
    it 'contains identifiers' do
      expect(pub_hash).to eq pub_hash_data
    end
  end

  context 'BibTeX record' do
    # Use the subject(:identifiers)

    let(:doi) { '8484848484' }
    let(:issn) { '234234' }
    let(:isbn) { '3233333' }

    let(:ids) do
      {
        'doi'        => doi,
        'doi_uri'    => "https://doi.org/#{doi}",
        'isbn'       => isbn,
        'isbn_uri'   => "http://searchworks.stanford.edu/?search_field=advanced&number=#{isbn}",
        'issn'       => issn,
        'issn_uri'   => "http://searchworks.stanford.edu/?search_field=advanced&number=#{issn}",
        # pmid is missing
      }
    end

    let(:pub_hash_data) do
      [
        { type: 'doi', id: ids['doi'], url: ids['doi_uri'] },
        { type: 'isbn', id: ids['isbn'], url: ids['isbn_uri'] },
        { type: 'issn', id: ids['issn'], url: ids['issn_uri'] },
      ]
    end

    it_behaves_like 'identifier_accessors'
    it_behaves_like 'to_h'
    it_behaves_like 'pub_hash'
  end

  context 'PubMed record as BibTeX article' do
    # Use the subject(:identifiers)
    let(:records) { BibTeX.open('spec/fixtures/bibtex/pubmed_record_10000166.bib') }
    let(:record) { records['@article'].first }

    let(:pmid) { '10000166' }

    let(:ids) do
      {
        'pmid'        => pmid,
        'pmid_uri'    => "https://www.ncbi.nlm.nih.gov/pubmed/#{pmid}",
      }
    end

    let(:pub_hash_data) do
      [
        { type: 'pmid', id: ids['pmid'], url: ids['pmid_uri'] },
      ]
    end

    it_behaves_like 'identifier_accessors'
    it_behaves_like 'to_h'
    it_behaves_like 'pub_hash'
  end

  describe 'Enumerable/Hash behavior' do
    # These convenience methods work by calling select methods on the Hash from to_h
    it 'works' do
      expect(identifiers).to be_an Enumerable
    end
    it 'has keys' do
      expect(identifiers.keys).to be_an Array
    end
    it 'has values' do
      expect(identifiers.values).to be_an Array
    end
    it 'can be an Array' do
      expect(identifiers.to_a).to be_an Array
    end
    it 'can be a JSON Hash' do
      expect(identifiers.to_json).to be_an String
      expect(JSON.parse(identifiers.to_json)).to be_an Hash
    end
    it 'can be filtered with reject' do
      result = identifiers.reject { |k, _v| k == 'doi' }
      expect(result).to be_an Hash
      expect(result.keys).not_to include('doi') # it does exist in identifiers
    end
    it 'can be filtered with select' do
      result = identifiers.select { |k, _v| k == 'doi' }
      expect(result).to be_an Hash
      expect(result.keys).to eq ['doi']
    end
    it 'does not respond to in-place modifier: reject!' do
      expect { identifiers.reject! { |k, _v| k == 'doi' } }.to raise_error(NoMethodError)
    end
    it 'does not respond to in-place modifier: select!' do
      expect { identifiers.select! { |k, _v| k == 'doi' } }.to raise_error(NoMethodError)
    end
  end
end
