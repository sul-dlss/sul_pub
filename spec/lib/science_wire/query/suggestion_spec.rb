require 'spec_helper'

describe ScienceWire::Query::Suggestion do
  include SuggestionQueries
  describe '#generate' do
    context 'with email and seed' do
      it 'returns a document with email and seed' do
        expect(described_class.new(
          'Doe', 'John', 'S', 'johnsdoe@example.com', [532_237], 'Journal Document'
        ).generate).to be_equivalent_to(journal_doc_email_and_seed)
      end
    end
    context 'with email and no seed' do
      it 'returns a document with email and no seed' do
        expect(described_class.new(
          'Smith', 'Jane', '', 'jane_smith@example.com', '', 'Journal Document'
        ).generate).to be_equivalent_to(journal_doc_email_no_seed)
      end
    end
    context 'with no email and no seed' do
      it 'returns a document with no email and no seed' do
        expect(described_class.new(
          'Brown', 'Charlie', '', '', '', 'Journal Document'
        ).generate).to be_equivalent_to(journal_doc_no_email_no_seed)
      end
    end
    context 'a conference proceeding' do
      it 'specifies a conference proceeding' do
        expect(described_class.new(
          'Brown', 'Charlie', '', '', '', 'Conference Proceeding Document'
        ).generate).to be_equivalent_to(conf_proc_doc_no_email_no_seed)
      end
    end
  end
end
