require 'spec_helper'

describe ScienceWire::Query::PublicationQueryByAuthorName do
  include AuthorDateQueries
  include AuthorNameQueries
  include InstitutionEmailQueries
  include PublicationQueryXsd
  let(:max_rows) { 200 }
  let(:seeds) { [1, 2, 3] }
  let(:institution) { 'Example University' }
  # The XSD is defined in fixture/queries/publication_query_xsd
  let(:xsd) { publication_query_xsd }
  let(:xml) { without_cdata(subject.generate) }

  shared_examples 'XSD validates' do
    it 'validates against an XSD' do
      doc = Nokogiri::XML(xml)
      validation = xsd.validate(doc) # returns an array of errors
      expect(validation).to be_empty # no errors
    end
  end

  describe '#generate' do
    subject { described_class.new(author_attributes, max_rows) }
    context 'common first and last name' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          'smith', 'james', '', '', '', institution
        )
      end
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(common_first_last_name))
      end
      it_behaves_like 'XSD validates'
    end
    context 'middle name only' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          '', '', 'mary', '', '', ''
        )
      end
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(middle_name_only))
      end
      it_behaves_like 'XSD validates'
    end
    context 'all attributes' do
      let(:author_attributes) do
        # last_name, first_name, middle_name, email, seed_list, institution
        ScienceWire::AuthorAttributes.new(
          'Smith', 'James', 'R', 'james.smith@example.com', seeds, institution
        )
      end
      it_behaves_like 'XSD validates'
    end
    context 'institution and email provided' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          'brown', 'charlie', '', 'cbrown@example.com', '', institution
        )
      end
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(institution_and_email_provided))
      end
      it_behaves_like 'XSD validates'
    end
    context 'institution and no email provided' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          'brown', 'charlie', '', '', '', institution
        )
      end
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(institution_and_no_email_provided))
      end
      it_behaves_like 'XSD validates'
    end
    context 'no institution but email provided' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          'brown', 'charlie', '', 'cbrown@example.com', '', ''
        )
      end
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(no_institution_but_email_provided))
      end
      it_behaves_like 'XSD validates'
    end
    context 'no institution no email provided' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          'brown', 'charlie', '', '', '', ''
        )
      end
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(no_institution_no_email_provided))
      end
      it_behaves_like 'XSD validates'
    end
    context 'author with dates' do
      let(:author_attributes) do
        # last_name, first_name, middle_name, email, seed_list, institution, start_date, end_date
        ScienceWire::AuthorAttributes.new(
          'Bloggs', 'Fred', nil, nil, nil, institution,
          Date.new(1990, 1, 1), Date.new(2000, 12, 31)
        )
      end
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(author_with_dates))
      end
      it_behaves_like 'XSD validates'
    end
  end
end

def without_cdata(cdata_string)
  cdata_string.gsub("<![CDATA[", '').gsub("]]>", '')
end
