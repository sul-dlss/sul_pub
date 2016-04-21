require 'spec_helper'

describe ScienceWire::Query::AuthorName do
  include AuthorNameQueries
  describe '#generate' do
    context 'common first and last name' do
      it 'generates a query' do
        an = described_class.new('james', '', 'smith', 200)
        expect(without_cdata(an.generate)).to be_equivalent_to(without_cdata(common_first_last_name))
      end
    end
    context 'middle name only' do
      it 'generates a query' do
        an = described_class.new('', 'mary', '', 200)
        expect(without_cdata(an.generate)).to be_equivalent_to(without_cdata(middle_name_only))
      end
    end
  end
end

def without_cdata(cdata_string)
  cdata_string.gsub("<![CDATA[", '').gsub("]]>", '')
end
