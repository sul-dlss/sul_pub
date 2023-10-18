# frozen_string_literal: true

describe WebOfScience::Identifiers do
  subject(:identifiers) { described_class.new wos_record }

  let(:wos_record_xml) { File.read('spec/fixtures/wos_client/wos_record_000288663100014.xml') }
  let(:wos_record) { WebOfScience::Record.new(record: wos_record_xml) }

  shared_examples 'identifier_accessors' do
    # when ids['x'] is nil, the expectation is that it should be nil
    it 'doi' do
      expect(identifiers.doi).to eq(ids['doi'])
    end

    it 'doi_uri' do
      expect(identifiers.doi_uri).to eq(ids['doi_uri'])
    end

    it 'eissn' do
      expect(identifiers.eissn).to eq(ids['eissn'])
    end

    it 'eissn_uri' do
      expect(identifiers.eissn_uri).to eq(ids['eissn_uri'])
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

    it 'uid' do
      expect(identifiers.uid).to eq(ids['WosUID'])
    end

    it 'uid is frozen' do
      expect { identifiers.uid[0] = 'a' }.to raise_error(RuntimeError)
    end

    it 'wos_item_id' do
      expect(identifiers.wos_item_id).to eq(ids['WosItemID'])
    end

    it 'wos_item_uri' do
      expect(identifiers.wos_item_uri).to eq(ids['WosItemURI'])
    end
  end

  shared_examples 'to_h' do
    let(:hash) { identifiers.to_h }

    it 'works' do
      expect(hash).to be_an Hash
    end

    it 'contains identifiers' do
      expect(hash).to eq ids.reject { |type, val| type == 'xref_doi' || val.nil? }
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

  context 'WOS record' do
    # Use the subject(:identifiers), it's a WOS-db record already.

    let(:doi) { '10.1007/s12630-011-9462-1' }

    let(:ids) do
      {
        'doi' => doi,
        'doi_uri' => "https://doi.org/#{doi}",
        'xref_doi' => doi,
        # eissn is missing
        'issn' => '0832-610X',
        'issn_uri' => 'http://searchworks.stanford.edu/?search_field=advanced&number=0832-610X',
        # pmid is missing
        'WosUID' => 'WOS:000288663100014',
        'WosItemID' => '000288663100014',
        'WosItemURI' => 'https://ws.isiknowledge.com/cps/openurl/service?url_ver=Z39.88-2004&rft_id=info:ut/000288663100014'
      }
    end

    let(:pub_hash_data) do
      [
        { type: 'doi', id: ids['doi'], url: ids['doi_uri'] },
        { type: 'issn', id: ids['issn'], url: ids['issn_uri'] },
        { type: 'WosItemID', id: ids['WosItemID'], url: ids['WosItemURI'] },
        { type: 'WosUID', id: ids['WosUID'] }
      ]
    end

    it 'works' do
      expect(identifiers).to be_an described_class
    end

    it 'raises ArgumentError with nil params' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it_behaves_like 'identifier_accessors'
    it_behaves_like 'to_h'
    it_behaves_like 'pub_hash'
    context 'the dark side' do
      it 'filters out identifiers that are not allowed' do
        # An xref_doi is used as the doi, if there is no doi value
        expect(identifiers.to_h).not_to include('xref_doi' => doi)
      end
    end
  end

  context 'MEDLINE record' do
    subject(:identifiers) { described_class.new medline_record }

    let(:medline_record_xml) { File.read('spec/fixtures/wos_client/medline_record_24452614.xml') }
    let(:medline_record) { WebOfScience::Record.new(record: medline_record_xml) }

    let(:ids) do
      {
        'doi' => '10.1038/psp.2013.66',
        'doi_uri' => 'https://doi.org/10.1038/psp.2013.66',
        # eissn is missing
        'issn' => '2163-8306',
        'issn_uri' => 'http://searchworks.stanford.edu/?search_field=advanced&number=2163-8306',
        'pmid' => '24452614',
        'pmid_uri' => 'https://www.ncbi.nlm.nih.gov/pubmed/24452614',
        'WosUID' => 'MEDLINE:24452614'
        # 'WosItemID'  is missing
        # 'WosItemURI' is missing
      }
    end

    let(:pub_hash_data) do
      [
        { type: 'doi', id: ids['doi'], url: ids['doi_uri'] },
        { type: 'issn', id: ids['issn'], url: ids['issn_uri'] },
        { type: 'pmid', id: ids['pmid'], url: ids['pmid_uri'] },
        { type: 'WosUID', id: ids['WosUID'] }
      ]
    end

    it_behaves_like 'identifier_accessors'
    it_behaves_like 'to_h'
    it_behaves_like 'pub_hash'
    it 'Wos-UID contains the pmid' do
      expect(identifiers.uid).to match ids['pmid']
    end
  end

  context 'WOS record with PMID' do
    subject(:identifiers) { described_class.new wos_pubmed_record }

    let(:wos_pubmed_record_xml) { File.read('spec/fixtures/wos_client/wos_record_000782396300001.xml') }
    let(:wos_pubmed_record) { WebOfScience::Record.new(record: wos_pubmed_record_xml) }

    let(:ids) do
      {
        'doi' => '10.1177/01455613221088697',
        'doi_uri' => 'https://doi.org/10.1177/01455613221088697',
        'eissn' => '1942-7522',
        'eissn_uri' => 'http://searchworks.stanford.edu/?search_field=advanced&number=1942-7522',
        'issn' => '0145-5613',
        'issn_uri' => 'http://searchworks.stanford.edu/?search_field=advanced&number=0145-5613',
        'pmid' => '35414268',
        'pmid_uri' => 'https://www.ncbi.nlm.nih.gov/pubmed/35414268',
        'WosUID' => 'WOS:000782396300001',
        'WosItemID' => '000782396300001',
        'WosItemURI' => 'https://ws.isiknowledge.com/cps/openurl/service?url_ver=Z39.88-2004&rft_id=info:ut/000782396300001'
      }
    end

    let(:pub_hash_data) do
      [
        { type: 'doi', id: ids['doi'], url: ids['doi_uri'] },
        { type: 'eissn', id: ids['eissn'], url: ids['eissn_uri'] },
        { type: 'issn', id: ids['issn'], url: ids['issn_uri'] },
        { type: 'pmid', id: ids['pmid'], url: ids['pmid_uri'] },
        { type: 'WosItemID', id: ids['WosItemID'], url: ids['WosItemURI'] },
        { type: 'WosUID', id: ids['WosUID'] }
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
      # rubocop:disable Style/HashExcept
      # also works as identifiers.to_h.except('doi'), but we're not testing that
      result = identifiers.reject { |k, _v| k == 'doi' }
      # rubocop:enable Style/HashExcept
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

  context 'can merge with links identifiers' do
    subject(:identifiers) { described_class.new wos_record4links }

    let(:wos_id) { '000346594100007' }
    let(:record4links) { File.read('spec/fixtures/wos_client/wos_record4links.html') }
    let(:wos_record4links) { WebOfScience::Record.new(encoded_record: record4links) }

    let(:links) { { '000346594100007' => { 'doi' => '10.1002/2013GB004790' } } }

    it 'has compatible keys in the Hash value' do
      # These sets of identifiers should both contain the 'doi' identifier
      expect(links[wos_id].keys & identifiers.keys).to eq ['doi']
    end
  end

  describe '#update' do
    let(:links) do
      # The links-API can return these for WosItemID '000288663100014'
      { 'doi' => '10.1007/s12630-011-9462-2', # artificially changed this to end with '2'
        'pmid' => '21253920' }
    end

    let(:dark_links) do
      links.merge(DarthVader: 'the dark side')
    end

    it 'returns a WebOfScience::Identifiers' do
      expect(identifiers.update(links)).to be_an described_class
    end

    it 'preserves existing identifiers' do
      # If it doesn't preserve them, the doi will end in `2` here
      expect(identifiers.update(links).to_h).to include('doi' => '10.1007/s12630-011-9462-1')
    end

    it 'duplicate identifiers are discarded' do
      # The inverse of the spec above, for completeness
      expect(identifiers.update(links).to_h).not_to include('doi' => '10.1007/s12630-011-9462-2')
    end

    it 'merges additional identifiers' do
      expect(identifiers.update(links).to_h).to include('pmid' => '21253920')
    end

    it 'excludes unknown identifiers' do
      expect(identifiers.update(dark_links).to_h).not_to include(DarthVader: 'the dark side')
    end

    it 'cannot be updated with any unknown key:value pairs' do
      identifiers.update(a: 1)
      expect(identifiers.to_h).not_to include(a: 1)
    end

    it 'does nothing and returns self when links.blank?' do
      expect(identifiers.update(nil)).to eq(identifiers)
    end
    # TODO: it should validate the data for known identifiers
    # TODO: this can use altmetrics identifier gem to validate identifier values

    it 'cannot be updated with any invalid identifier values', skip: 'not sure why this is skipped' do
      identifiers.update('pmid' => 1)
      expect(identifiers.to_h).not_to include('pmid' => 1)
    end
  end
end
