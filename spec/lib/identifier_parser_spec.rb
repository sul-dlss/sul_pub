# Load Shared Examples
require Rails.root.join('spec', 'support', 'identifier_parser_shared_examples.rb')

describe IdentifierParser do
  let(:identifier_type) { 'other' }
  let(:identifier_value) { 'a value' }
  let(:identifier_uri) { 'a uri' }
  let(:identifier) do
    FactoryGirl.create(:publication_identifier,
                       identifier_type: identifier_type,
                       identifier_value: identifier_value,
                       identifier_uri: identifier_uri)
  end
  let(:parser) { described_class.new(identifier) }

  let(:null_logger) { Logger.new('/dev/null') }

  before do
    allow(Logger).to receive(:new).and_return(null_logger)
  end

  # Happy paths
  # - the base class does not extract or modify anything
  it_behaves_like 'parser_new_works'
  it_behaves_like 'valid_identifier'
  it_behaves_like 'it_changes_nothing'

  # Un-happy paths
  # - the base class allows anything except blank data
  it_behaves_like 'blank_identifiers_raise_exception'

  # ---
  # Identifiers that are not changed in any way

  context '#update using an identifier it does not handle' do
    it_behaves_like 'it_changes_nothing'
  end

  context '#update using a WoSItemID' do
    let(:identifier) do
      FactoryGirl.create(:publication_identifier,
                         identifier_type:  'WoSItemID',
                         identifier_value: 'A1976CM52800051',
                         identifier_uri:   'https://ws.isiknowledge.com/cps/openurl/service?url_ver=Z39.88-2004&rft_id=info:ut/A1976CM52800051')
    end

    it_behaves_like 'it_changes_nothing'
  end

  context '#update using a PublicationItemID' do
    let(:identifier) do
      FactoryGirl.create(:publication_identifier,
                         identifier_type:  'PublicationItemID',
                         identifier_value: '13276514',
                         identifier_uri:   nil)
    end

    it_behaves_like 'it_changes_nothing'
  end

  # ---
  # Base class behavior

  context '#extractor' do
    it 'is not called' do
      expect(parser).not_to receive(:extractor)
      parser.update
    end
    it 'if called - it raises NotImplementedError' do
      expect { parser.send(:extractor) }.to raise_error(NotImplementedError)
    end
  end
end
