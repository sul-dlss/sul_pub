describe ParseIdentifier do
  let(:blank_identifier) do
    FactoryGirl.create(:publication_identifier,
                       identifier_type: 'some-blank-identifier',
                       identifier_value: '',
                       identifier_uri: ''
                      )
  end

  let(:doi_value) { '10.1038/ncomms3199' }
  let(:doi_uri) { "http://dx.doi.org/#{doi_value}" }
  let(:doi_identifier) do
    FactoryGirl.create(:publication_identifier,
                       identifier_type: 'doi',
                       identifier_value: doi_value,
                       identifier_uri: doi_uri
                      )
  end

  describe '#new' do
    it 'works' do
      parser = described_class.new(doi_identifier)
      expect(parser).not_to be_nil
    end
    it 'raises RuntimeError when value and uri are blank' do
      expect { described_class.new(blank_identifier) }.to raise_error(RuntimeError)
    end
  end

  describe '#update' do
    it 'works' do
      parser = described_class.new(doi_identifier)
      expect(parser.update).to be_an PublicationIdentifier
    end
  end

  # ---
  # Shared Examples

  shared_examples 'DOI_works' do
    it '#doi works' do
      expect(parser.doi).to eq doi_value
    end
    it '#doi_uri works' do
      expect(parser.doi_uri).to eq doi_uri
    end
  end

  shared_examples 'DOI_nil' do
    it '#doi is blank' do
      expect(parser.doi).to be_nil
    end
    it '#doi_uri is blank' do
      expect(parser.doi_uri).to be_nil
    end
  end

  shared_examples 'it_does_not_change_identifier' do
    # By design, the parser should preserve the input identifier
    it 'update does not change identifier' do
      expect { parser.update }.not_to change { identifier }
    end
  end

  shared_examples 'it_changes_value' do
    it 'updates the value' do
      expect { parser.update }.to change { parser.value }
    end
  end

  shared_examples 'it_changes_uri' do
    it 'updates the uri' do
      expect { parser.update }.to change { parser.uri }
    end
  end

  shared_examples 'it_does_not_change_value' do
    it 'does not change value' do
      expect { parser.update }.not_to change { parser.value }
    end
  end

  shared_examples 'it_does_not_change_uri' do
    it 'does not change the uri' do
      expect { parser.update }.not_to change { parser.uri }
    end
  end

  shared_examples 'it_changes_nothing' do
    it_behaves_like 'it_does_not_change_identifier'
    it_behaves_like 'it_does_not_change_value'
    it_behaves_like 'it_does_not_change_uri'
  end

  # ---
  # DOI Identifiers that require no changes

  context 'DOI is valid' do
    let(:identifier) do
      FactoryGirl.create(:publication_identifier,
                         identifier_type: 'doi',
                         identifier_value: doi_value,
                         identifier_uri: doi_uri
                        )
    end
    let(:parser) { described_class.new(identifier) }

    it_behaves_like 'DOI_works'
    it_behaves_like 'it_changes_nothing'
  end

  # ---
  # DOI Identifiers that are changed in some way

  context '#update using only a valid DOI URI' do
    let(:identifier) do
      FactoryGirl.create(:publication_identifier,
                         identifier_type: 'doi',
                         identifier_uri: doi_uri
                        )
    end
    let(:parser) { described_class.new(identifier) }

    it_behaves_like 'DOI_works'
    it_behaves_like 'it_does_not_change_identifier'
    it_behaves_like 'it_does_not_change_uri'
    it_behaves_like 'it_changes_value'
  end

  context '#update using only a valid DOI value' do
    let(:identifier) do
      FactoryGirl.create(:publication_identifier,
                         identifier_type: 'doi',
                         identifier_value: doi_value
                        )
    end
    let(:parser) { described_class.new(identifier) }

    it_behaves_like 'DOI_works'
    it_behaves_like 'it_does_not_change_identifier'
    it_behaves_like 'it_does_not_change_value'
    it_behaves_like 'it_changes_uri'
  end

  context '#update using a valid DOI value, but in the URI' do
    let(:identifier) do
      FactoryGirl.create(:publication_identifier,
                         identifier_type: 'doi',
                         identifier_uri: doi_value
                        )
    end
    let(:parser) { described_class.new(identifier) }

    it_behaves_like 'DOI_works'
    it_behaves_like 'it_does_not_change_identifier'
    it_behaves_like 'it_changes_uri'
    it_behaves_like 'it_changes_value'
  end

  # ---
  # Other identifiers that are not changed in any way

  context '#update using an identifier it does not handle' do
    let(:identifier) do
      FactoryGirl.create(:publication_identifier,
                         identifier_type: 'Huh?',
                         identifier_value: 'some-value',
                         identifier_uri: 'some-uri'
                        )
    end
    let(:parser) { described_class.new(identifier) }

    it_behaves_like 'it_changes_nothing'
    it_behaves_like 'DOI_nil'
  end

  context '#update using a WoSItemID' do
    let(:identifier) do
      FactoryGirl.create(:publication_identifier,
                         identifier_type:  'WoSItemID',
                         identifier_value: 'A1976CM52800051',
                         identifier_uri:   'https://ws.isiknowledge.com/cps/openurl/service?url_ver=Z39.88-2004&rft_id=info:ut/A1976CM52800051'
                        )
    end
    let(:parser) { described_class.new(identifier) }

    it_behaves_like 'it_changes_nothing'
    it_behaves_like 'DOI_nil'
  end

  context '#update using a PublicationItemID' do
    let(:identifier) do
      FactoryGirl.create(:publication_identifier,
                         identifier_type:  'PublicationItemID',
                         identifier_value: '13276514',
                         identifier_uri:   nil
                        )
    end
    let(:parser) { described_class.new(identifier) }

    it_behaves_like 'it_changes_nothing'
    it_behaves_like 'DOI_nil'
  end
end
