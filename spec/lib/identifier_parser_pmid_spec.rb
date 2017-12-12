# Load Shared Examples
require Rails.root.join('spec', 'support', 'identifier_parser_shared_examples.rb')

describe IdentifierParserPMID do
  let(:identifier_type) { 'PMID' }
  let(:identifier_value) { '10002407' }
  let(:identifier_uri) { "https://www.ncbi.nlm.nih.gov/pubmed/#{identifier_value}" }
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
  it_behaves_like 'update_works_with_only_valid_uri'
  it_behaves_like 'update_works_with_only_valid_value'
  it_behaves_like 'update_works_with_only_valid_value_in_uri'

  # Un-happy paths
  it_behaves_like 'blank_identifiers_raise_exception'
  it_behaves_like 'other_identifiers_raise_exception'
  let(:invalid_value) { '101-038' }
  it_behaves_like 'invalid_value'
end
