require 'spec_helper'

describe ScienceWire::Query::Suggestion do
  include SuggestionQueries
  describe '#generate' do
    subject { described_class.new(author_attributes, category) }
    context 'with email and seed' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          'Doe', 'John', 'S', 'johnsdoe@example.com', [532_237]
        )
      end
      let(:category) { 'Journal Document' }
      it 'returns a document with email and seed' do
        expect(subject.generate).to be_equivalent_to(journal_doc_email_and_seed)
      end
    end
    context 'with email and no seed' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          'Smith', 'Jane', '', 'jane_smith@example.com', ''
        )
      end
      let(:category) { 'Journal Document' }
      it 'returns a document with email and no seed' do
        expect(subject.generate).to be_equivalent_to(journal_doc_email_no_seed)
      end
    end
    context 'with no email and no seed' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          'Brown', 'Charlie', '', '', ''
        )
      end
      let(:category) { 'Journal Document' }
      it 'returns a document with no email and no seed' do
        expect(subject.generate).to be_equivalent_to(journal_doc_no_email_no_seed)
      end
    end
  end
end
