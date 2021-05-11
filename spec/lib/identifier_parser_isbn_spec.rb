# Load Shared Examples
require Rails.root.join('spec', 'support', 'identifier_parser_shared_examples.rb')

describe IdentifierParserISBN do
  let(:identifier_type) { 'isbn' }
  let(:identifier_value) { '9781904842781' }
  let(:identifier_uri) { nil }
  let(:identifier) do
    FactoryBot.create(:publication_identifier,
                      identifier_type: identifier_type,
                      identifier_value: identifier_value,
                      identifier_uri: identifier_uri
                     )
  end
  let(:parser) { described_class.new(identifier) }

  let(:null_logger) { Logger.new('/dev/null') }

  before do
    allow(Logger).to receive(:new).and_return(null_logger)
  end

  # Happy paths
  it_behaves_like 'parser_new_works'
  it_behaves_like 'valid_identifier'

  # Un-happy paths
  it_behaves_like 'blank_identifiers_raise_exception'
  it_behaves_like 'other_identifiers_raise_exception'
  let(:invalid_value) { '978' }
  it_behaves_like 'invalid_value'

  # ---
  # ISBN Identifiers on the happy path
  # - this differs from DOI & PMID because it has no URI

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
    it_behaves_like 'it_does_not_change_uri'
  end

  context '#update using a valid value, but in the URI' do
    let(:identifier) do
      FactoryBot.create(:publication_identifier,
                        identifier_type: identifier_type,
                        identifier_uri: identifier_value
                       )
    end
    let(:parser) { described_class.new(identifier) }

    it_behaves_like 'parser_works'
    it_behaves_like 'it_does_not_change_identifier'
    it_behaves_like 'it_changes_uri'
    it_behaves_like 'it_changes_value'
  end
end
