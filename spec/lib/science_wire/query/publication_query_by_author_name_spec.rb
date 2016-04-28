require 'spec_helper'

describe ScienceWire::Query::PublicationQueryByAuthorName do
  include AuthorNameQueries
  include InstitutionEmailQueries
  let(:max_rows) { 200 }
  let(:seeds) { [1, 2, 3] }
  let(:institution) { 'Example University' }
  # The XSD is defined in fixture/queries/author_name_queries
  let(:xsd) { author_publication_query_xsd }
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
          'brown', 'charlie', '', 'cbrown@example.com', '', 'Example University'
        )
      end
      let(:max_rows) { '200' }
      it 'generates a query' do
        expect(without_cdata(subject.generate)).to be_equivalent_to(without_cdata(institution_and_email_provided))
      end
    end
    context 'institution and no email provided' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          'brown', 'charlie', '', '', '', 'Example University'
        )
      end
      let(:max_rows) { '200' }
      it 'generates a query' do
        expect(without_cdata(subject.generate)).to be_equivalent_to(without_cdata(institution_and_no_email_provided))
      end
    end
    context 'no institution but email provided' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          'brown', 'charlie', '', 'cbrown@example.com', '', ''
        )
      end
      let(:max_rows) { '200' }
      it 'generates a query' do
        expect(without_cdata(subject.generate)).to be_equivalent_to(without_cdata(no_institution_but_email_provided))
      end
    end
  end
end

def without_cdata(cdata_string)
  cdata_string.gsub("<![CDATA[", '').gsub("]]>", '')
end
