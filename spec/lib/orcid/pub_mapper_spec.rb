# frozen_string_literal: true

describe Orcid::PubMapper do
  let(:work) { described_class.map(pub_hash).with_indifferent_access }

  let(:base_pub_hash) do
    {
      type: 'article',
      title: 'Computing Machinery and Intelligence',
      identifier: [
        {
          type: 'doi',
          id: '10.1093/mind/LIX.236.433',
          url: 'https://doi.org/10.1093%2Fmind%2FLIX.236.433'
        }
      ],
      abstract: 'Can machines think?',
      date: '1950-10-01T00:00:00',
      author: [
        {
          name: 'Alan Turing'
        }
      ],
      journal: {
        name: 'Mind'
      }
    }
  end

  let(:pub_hash) { base_pub_hash }

  it 'maps type' do
    expect(work[:type]).to eq('journal-article')
  end

  it 'sets visibility' do
    expect(work[:visibility]).to eq('public')
  end

  it 'maps title' do
    expect(work[:title][:title][:value]).to eq('Computing Machinery and Intelligence')
  end

  it 'maps identifier' do
    expect(work['external-ids']['external-id'].size).to eq(1)
    expect(work['external-ids']['external-id'].first).to eq({
                                                              'external-id-type' => 'doi',
                                                              'external-id-value' => '10.1093/mind/LIX.236.433',
                                                              'external-id-url' => 'https://doi.org/10.1093%2Fmind%2FLIX.236.433',
                                                              'external-id-relationship' => 'self'
                                                            })
  end

  it 'maps abstract' do
    expect(work['short-description']).to eq('Can machines think?')
  end

  it 'maps date' do
    expect(work['publication-date']).to eq({
                                             'year' => { 'value' => '1950' },
                                             'month' => { 'value' => '10' },
                                             'day' => { 'value' => '01' }
                                           })
  end

  it 'maps bibtex' do
    expect(work['citation']).to eq({
                                     'citation-type' => 'bibtex',
                                     'citation-value' => '@article{alan turing, title={Computing Machinery and Intelligence}, journal={Mind}, author={Alan Turing}}'
                                   })
  end

  it 'maps author' do
    expect(work['contributors']['contributor'].size).to eq(1)
    expect(work['contributors']['contributor'].first).to eq(
      {
        'contributor-orcid' => nil,
        'credit-name' => {
          'value' => 'Alan Turing'
        },
        'contributor-email' => nil,
        'contributor-attributes' => {
          'contributor-sequence' => nil,
          'contributor-role' => 'author'
        }
      }
    )
  end

  it 'maps journal title' do
    expect(work['journal-title']['value']).to eq('Mind')
  end

  context 'when unmappable type' do
    let(:pub_hash) do
      base_pub_hash.dup.tap { |pub_hash| pub_hash[:type] = 'workingPaper' }
    end

    it 'raises' do
      expect { work }.to raise_error(Orcid::PubMapper::PubMapperError, 'Unmapped publication type')
    end
  end

  context 'when missing title' do
    let(:pub_hash) { base_pub_hash.except(:title) }

    it 'raises' do
      expect { work }.to raise_error(Orcid::PubMapper::PubMapperError, 'Title is required')
    end
  end

  context 'when year but no date' do
    let(:pub_hash) do
      base_pub_hash.dup.tap do |pub_hash|
        pub_hash.delete(:date)
        pub_hash[:year] = '1950'
      end
    end

    it 'maps year' do
      expect(work['publication-date']).to eq({
        year: { value: '1950' },
        month: nil,
        day: nil
      }.with_indifferent_access)
    end
  end

  context 'when date is unparseable' do
    let(:pub_hash) do
      base_pub_hash.dup.tap do |pub_hash|
        pub_hash[:date] = '1950-xx-xx'
      end
    end

    it 'does not map' do
      expect(work['publication-date']).to be_nil
    end
  end

  context 'when year is unparseable' do
    let(:pub_hash) do
      base_pub_hash.dup.tap do |pub_hash|
        pub_hash.delete(:date)
        pub_hash[:year] = '195?'
      end
    end

    it 'does not map' do
      expect(work['publication-date']).to be_nil
    end
  end

  context 'when year has whitespace' do
    let(:pub_hash) do
      base_pub_hash.dup.tap do |pub_hash|
        pub_hash.delete(:date)
        pub_hash[:year] = ' 1950'
      end
    end

    it 'maps without whitespace' do
      expect(work['publication-date']).to eq({
        year: { value: '1950' },
        month: nil,
        day: nil
      }.with_indifferent_access)
    end
  end

  context 'when a book' do
    let(:pub_hash) do
      {
        type: 'book',
        booktitle: 'Concepts: Where Cognitive Science Went Wrong',
        identifier: [
          {
            type: 'isbn',
            id: '0-19-823636-0'
          }
        ],
        author: [
          {
            name: 'Jerry A. Fodor'
          }
        ]
      }
    end

    it 'maps title' do
      expect(work[:title][:title][:value]).to eq('Concepts: Where Cognitive Science Went Wrong')
    end
  end

  context 'when a conference paper' do
    let(:pub_hash) do
      {
        type: 'inproceedings',
        title: 'Turing\'s Test Revisited',
        identifier: [
          {
            type: 'doi',
            id: '10.1109/ICSMC.1988.754236'
          }
        ],
        conference: {
          name: 'IEEE International Conference on Systems, Man, and Cybernetics'
        }
      }
    end

    it 'maps conference name' do
      expect(work[:'journal-title'][:value]).to eq('IEEE International Conference on Systems, Man, and Cybernetics')
    end
  end
end
