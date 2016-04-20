require 'spec_helper'

describe ScienceWire::Query::ConferenceProceedingDocumentSuggestion do
  include SuggestionQueries
  subject { described_class.new(author_attributes) }
  let(:author_attributes) do
    ScienceWire::AuthorAttributes.new(
      'Brown', 'Charlie', '', '', ''
    )
  end
  it 'returns a suggestion query with conference proceeding document' do
    expect(subject.generate).to be_equivalent_to(conf_proc_doc_no_email_no_seed)
  end
end
