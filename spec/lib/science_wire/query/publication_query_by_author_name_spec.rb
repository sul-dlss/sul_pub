
describe ScienceWire::Query::PublicationQueryByAuthorName do
  # import modules from spec/fixtures/queries
  include AuthorDateQueries
  include AuthorNameQueries
  include InstitutionEmailQueries
  include PublicationQueryXsd
  let(:charlie_brown_name) { Agent::AuthorName.new('brown', 'charlie', '') }
  let(:max_rows) { 200 }
  let(:seeds) { [1, 2, 3] }
  let(:institution) { 'Example University' }
  # The XSD is defined in spec/fixtures/queries/publication_query_xsd
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
    before do
      allow(Settings.HARVESTER).to receive(:USE_FIRST_INITIAL).and_return(true)
    end
    subject { described_class.new(author_attributes, max_rows) }
    context 'common first and last name' do
      let(:author_name) { Agent::AuthorName.new('smith', 'james', '') }
      let(:author_attributes) { ScienceWire::AuthorAttributes.new(author_name, '', '', institution) }
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(common_first_last_name))
      end
      it_behaves_like 'XSD validates'
    end
    context 'middle name only' do
      let(:author_name) { Agent::AuthorName.new('', '', 'mary') }
      let(:author_attributes) { ScienceWire::AuthorAttributes.new(author_name, '', '', default_institution) }
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(middle_name_only))
      end
      it_behaves_like 'XSD validates'
    end
    context 'all attributes' do
      let(:author_name) { Agent::AuthorName.new('Smith', 'James', 'R') }
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(author_name, 'james.smith@example.com', seeds, institution)
      end
      it_behaves_like 'XSD validates'
    end
    context 'institution and email provided' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(charlie_brown_name, 'cbrown@example.com', '', institution)
      end
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(institution_and_email_provided))
      end
      it_behaves_like 'XSD validates'
    end
    context 'institution and no email provided' do
      let(:author_attributes) { ScienceWire::AuthorAttributes.new(charlie_brown_name, '', '', institution) }
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(institution_and_no_email_provided))
      end
      it_behaves_like 'XSD validates'
    end
    context 'no institution but email provided' do
      let(:author_attributes) { ScienceWire::AuthorAttributes.new(charlie_brown_name, 'cbrown@example.com') }
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(no_institution_but_email_provided))
      end
      it_behaves_like 'XSD validates'
    end
    context 'no institution no email provided' do
      let(:author_attributes) { ScienceWire::AuthorAttributes.new(charlie_brown_name, '') }
      it 'generates a query' do
        expect(xml).to be_equivalent_to(without_cdata(no_institution_no_email_provided))
      end
      it_behaves_like 'XSD validates'
    end
    context 'author with dates' do
      let(:author_name) { Agent::AuthorName.new('Bloggs', 'Fred', '') }
      let(:author_attributes) do
        # name, email, seed_list, institution, start_date, end_date
        ScienceWire::AuthorAttributes.new(
          author_name, nil, nil, institution,
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
