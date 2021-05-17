# frozen_string_literal: true

describe WebOfScience::Mapper do
  subject(:mapper) { described_class.new(wos_record) }

  let(:wos_encoded_xml) { File.read('spec/fixtures/wos_client/wos_encoded_record.html') }
  let(:wos_record) { WebOfScience::Record.new(encoded_record: wos_encoded_xml) }

  describe '#new' do
    it 'works with WOS records' do
      expect(mapper).to be_an described_class
    end

    it 'raises ArgumentError with nil params' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError with anything other than WebOfScience::Record' do
      expect { described_class.new('could be xml') }.to raise_error(ArgumentError)
    end
  end

  describe '#pub_hash' do
    it 'is not implemented in the base class' do
      expect { mapper.pub_hash }.to raise_error(NotImplementedError)
    end
  end
end
