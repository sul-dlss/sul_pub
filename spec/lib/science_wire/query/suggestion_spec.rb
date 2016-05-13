require 'spec_helper'

describe ScienceWire::Query::Suggestion do
  include SuggestionQueries
  include SuggestionQueryXsd
  # The XSD is defined in fixture/queries/suggestion_query_xsd
  let(:xsd) { suggestion_query_xsd }
  let(:xml) { subject.generate }

  shared_examples 'XSD validates' do
    it 'validates against an XSD' do
      doc = Nokogiri::XML(xml)
      validation = xsd.validate(doc) # returns an array of errors
      expect(validation).to be_empty # no errors
    end
  end

  describe '#generate' do
    subject { described_class.new(author_attributes, category) }

    context 'with default_institution' do
      context 'with email and seed' do
        let(:author_name) { ScienceWire::AuthorName.new('Doe', 'John', 'S') }
        let(:author_attributes) do
          ScienceWire::AuthorAttributes.new(
            author_name, 'johnsdoe@example.com', [532_237], default_institution
          )
        end
        let(:category) { 'Journal Document' }
        it 'returns a document with email and seed' do
          expect(xml).to be_equivalent_to(journal_doc_email_and_seed)
        end
        it_behaves_like 'XSD validates'
      end

      context 'with email and no seed' do
        let(:author_name) { ScienceWire::AuthorName.new('Smith', 'Jane', '') }
        let(:author_attributes) do
          ScienceWire::AuthorAttributes.new(
            author_name, 'jane_smith@example.com', '', default_institution
          )
        end
        let(:category) { 'Journal Document' }
        it 'returns a document with email and no seed' do
          expect(xml).to be_equivalent_to(journal_doc_email_no_seed)
        end
        it_behaves_like 'XSD validates'
      end

      context 'with no email and no seed' do
        let(:author_name) { ScienceWire::AuthorName.new('Brown', 'Charlie', '') }
        let(:author_attributes) do
          ScienceWire::AuthorAttributes.new(
            author_name, '', '', default_institution
          )
        end
        let(:category) { 'Journal Document' }
        it 'returns a document with no email and no seed' do
          expect(xml).to be_equivalent_to(journal_doc_no_email_no_seed)
        end
        it_behaves_like 'XSD validates'
      end
    end
  end
end
