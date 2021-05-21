# frozen_string_literal: true

describe Orcid::PubMapper do
  let(:work) { described_class.map(pub_hash) }

  let(:base_pub_hash) do
    {
      type: 'article',
      title: 'Computing Machinery and Intelligence',
      identifier: [
        {
          type: 'doi',
          id: 'doi:10.1093/mind/LIX.236.433',
          url: 'https://doi.org/10.1093%2Fmind%2FLIX.236.433'
        }
      ]
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
                                                              'external-id-value' => 'doi:10.1093/mind/LIX.236.433',
                                                              'external-id-url' => 'https://doi.org/10.1093%2Fmind%2FLIX.236.433',
                                                              'external-id-relationship' => 'self'
                                                            })
  end

  context 'when unmappable type' do
    let(:pub_hash) do
      base_pub_hash.dup.tap { |pub_hash| pub_hash[:type] = 'workingPaper' }
    end

    it 'raises' do
      expect { work }.to raise_error('Unmapped publication type')
    end
  end

  context 'when missing title' do
    let(:pub_hash) { base_pub_hash.except(:title) }

    it 'raises' do
      expect { work }.to raise_error('Title is required')
    end
  end

  context 'when missing identifier' do
    let(:pub_hash) { base_pub_hash.except(:identifier) }

    it 'raises' do
      expect { work }.to raise_error('An identifier is required')
    end
  end

  context 'when missing identifier type' do
    let(:pub_hash) do
      pub_hash = base_pub_hash.dup
      pub_hash[:identifier] << {
        type: '',
        id: '000324929800081'
      }
      pub_hash
    end

    it 'skips' do
      expect(work['external-ids']['external-id'].size).to eq(1)
    end
  end

  context 'when missing identifier value' do
    let(:pub_hash) do
      pub_hash = base_pub_hash.dup
      pub_hash[:identifier] << {
        type: 'WosUID',
        id: ''
      }
      pub_hash
    end

    it 'skips' do
      expect(work['external-ids']['external-id'].size).to eq(1)
    end
  end

  context 'when unmappable identifier type' do
    let(:pub_hash) do
      pub_hash = base_pub_hash.dup
      pub_hash[:identifier] << {
        type: 'SULPubId',
        id: '123'
      }
      pub_hash
    end

    it 'skips' do
      expect(work['external-ids']['external-id'].size).to eq(1)
    end
  end
end
