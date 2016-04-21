require 'spec_helper'

describe ScienceWire::Query::PublicationQueryByAuthorName do
  include AuthorNameQueries
  describe '#generate' do
    subject { described_class.new(author_attributes, max_rows) }
    context 'common first and last name' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          'smith', 'james', '', '', ''
        )
      end
      let(:max_rows) { '200' }
      it 'generates a query' do
        expect(without_cdata(subject.generate)).to be_equivalent_to(without_cdata(common_first_last_name))
      end
    end
    context 'middle name only' do
      let(:author_attributes) do
        ScienceWire::AuthorAttributes.new(
          '', '', 'mary', '', ''
        )
      end
      let(:max_rows) { '200' }
      it 'generates a query' do
        expect(without_cdata(subject.generate)).to be_equivalent_to(without_cdata(middle_name_only))
      end
    end
  end
end

def without_cdata(cdata_string)
  cdata_string.gsub("<![CDATA[", '').gsub("]]>", '')
end
