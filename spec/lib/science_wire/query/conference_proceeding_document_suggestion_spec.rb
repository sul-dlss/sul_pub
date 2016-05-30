require 'spec_helper'
SingleCov.covered!

describe ScienceWire::Query::ConferenceProceedingDocumentSuggestion do
  include SuggestionQueries
  subject { described_class.new(author_attributes) }
  let(:author_name) { ScienceWire::AuthorName.new('Brown', 'Charlie', '') }
  let(:author_attributes) do
    ScienceWire::AuthorAttributes.new(author_name, '', '', default_institution)
  end
  it 'returns a suggestion query with conference proceeding document' do
    expect(subject.generate).to be_equivalent_to(conf_proc_doc_no_email_no_seed)
  end
end
