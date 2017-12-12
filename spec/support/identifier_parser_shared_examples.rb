
# ---
# Shared Examples for IdentifierParser* specs

shared_examples 'parser_new_works' do
  describe '#new' do
    it 'works' do
      expect(parser).to be_an described_class
    end
    it 'raises ArgumentError' do
      expect { described_class.new('Darth Maul') }.to raise_error(ArgumentError)
    end
  end
end

shared_examples 'parser_works' do
  it '#value works' do
    expect(parser.value).to eq identifier_value
  end
  it '#uri works' do
    expect(parser.uri).to eq identifier_uri
  end
  it '#validates OK' do
    expect(parser.valid?).to be true
  end
  it '#update works' do
    expect(parser.update).to be_an PublicationIdentifier
  end
  describe '#identifier' do
    it 'works' do
      expect(parser.identifier).to be_an Hash
    end
    it 'has :type String' do
      expect(parser.identifier[:type]).to be_an String
    end
    it 'has :id String' do
      expect(parser.identifier[:id]).to be_an String
    end
    it 'might have :url String' do
      expect(parser.identifier[:url]).to be_an String if parser.uri
    end
  end
end

shared_examples 'valid_identifier' do
  it_behaves_like 'parser_works'
  it_behaves_like 'it_changes_nothing'
  it_behaves_like 'it_is_impervious_to_outside_changes'
end

shared_examples 'it_is_impervious_to_outside_changes' do
  it 'memoises value data on init and cannot change it otherwise' do
    parser.value # initialize it with valid data
    expect do
      identifier.identifier_value = 'ha ha, now here is something different'
    end.not_to change { parser.value }
  end
  it 'cannot change value after init' do
    expect { parser.value = 'try me' }.to raise_error(NoMethodError)
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
    expect(parser.value).not_to eq identifier['identifier_value']
  end
end

shared_examples 'it_changes_uri' do
  it 'updates the uri' do
    expect(parser.uri).not_to eq identifier['identifier_uri']
  end
end

shared_examples 'it_does_not_change_value' do
  it 'does not change value' do
    expect(parser.value).to eq identifier['identifier_value']
  end
end

shared_examples 'it_does_not_change_uri' do
  it 'does not change the uri' do
    expect(parser.uri).to eq identifier['identifier_uri']
  end
end

shared_examples 'it_changes_nothing' do
  it_behaves_like 'it_does_not_change_identifier'
  it_behaves_like 'it_does_not_change_value'
  it_behaves_like 'it_does_not_change_uri'
end

shared_examples 'invalid_type' do
  it 'raises IdentifierParserTypeError' do
    expect { parser }.to raise_error(IdentifierParserTypeError)
  end
end

shared_examples 'invalid_value' do
  context 'identifier is invalid' do
    let(:invalid_identifier) do
      FactoryBot.create(:publication_identifier,
                         identifier_type: identifier_type,
                         identifier_value: invalid_value
                        )
    end

    it 'raises IdentifierParserInvalidError when value and uri do not validate' do
      expect { described_class.new(invalid_identifier) }.to raise_error(IdentifierParserInvalidError)
    end
  end
end

shared_examples 'blank_identifiers_raise_exception' do
  let(:blank_identifier) { FactoryBot.create(:blank_publication_identifier, identifier_type: identifier_type) }

  it 'raises IdentifierParserEmptyError when value and uri are blank' do
    expect { described_class.new(blank_identifier) }.to raise_error(IdentifierParserEmptyError)
  end
end

shared_examples 'other_identifiers_raise_exception' do
  context '#update using an identifier it does not handle' do
    let(:identifier) do
      FactoryBot.create(:publication_identifier,
                         identifier_type: 'Huh?',
                         identifier_value: 'some-value',
                         identifier_uri: 'some-uri'
                        )
    end

    it_behaves_like 'invalid_type'
  end

  context '#update using a WoSItemID' do
    let(:identifier) do
      FactoryBot.create(:publication_identifier,
                         identifier_type:  'WoSItemID',
                         identifier_value: 'A1976CM52800051',
                         identifier_uri:   'https://ws.isiknowledge.com/cps/openurl/service?url_ver=Z39.88-2004&rft_id=info:ut/A1976CM52800051'
                        )
    end

    it_behaves_like 'invalid_type'
  end

  context '#update using a PublicationItemID' do
    let(:identifier) do
      FactoryBot.create(:publication_identifier,
                         identifier_type:  'PublicationItemID',
                         identifier_value: '13276514',
                         identifier_uri:   nil
                        )
    end

    it_behaves_like 'invalid_type'
  end
end

shared_examples 'update_works_with_only_valid_uri' do
  context '#update using only a valid URI' do
    let(:identifier) do
      FactoryBot.create(:publication_identifier,
                         identifier_type: identifier_type,
                         identifier_uri: identifier_uri
                        )
    end

    it_behaves_like 'parser_works'
    it_behaves_like 'it_does_not_change_identifier'
    it_behaves_like 'it_does_not_change_uri'
    it_behaves_like 'it_changes_value'
  end
end

shared_examples 'update_works_with_only_valid_value' do
  context '#update using only a valid value' do
    let(:identifier) do
      FactoryBot.create(:publication_identifier,
                         identifier_type: identifier_type,
                         identifier_value: identifier_value
                        )
    end

    it_behaves_like 'parser_works'
    it_behaves_like 'it_does_not_change_identifier'
    it_behaves_like 'it_does_not_change_value'
    it_behaves_like 'it_changes_uri'
  end
end

shared_examples 'update_works_with_only_valid_value_in_uri' do
  context '#update using a valid value, but in the URI' do
    let(:identifier) do
      FactoryBot.create(:publication_identifier,
                         identifier_type: identifier_type,
                         identifier_uri: identifier_value
                        )
    end

    it_behaves_like 'parser_works'
    it_behaves_like 'it_does_not_change_identifier'
    it_behaves_like 'it_changes_uri'
    it_behaves_like 'it_changes_value'
  end
end

