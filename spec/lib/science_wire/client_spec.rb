require 'spec_helper'

describe ScienceWire::Client do
  describe '#initialize' do
    it 'requires licence_id and host' do
      expect { subject }.to raise_error(
        ArgumentError, 'missing keywords: licence_id, host'
      )
    end
  end
  describe 'included methods' do
    subject do
      described_class.new(licence_id: 'license', host: 'www.example.com')
    end
    it 'responds to them' do
      [
        :matched_publication_item_ids_for_author,
        :send_publication_query,
        :retrieve_publication_query
      ].each do |method|
        expect(subject).to respond_to method
      end
    end
  end
end
