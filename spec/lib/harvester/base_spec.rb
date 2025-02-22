# frozen_string_literal: true

describe Harvester::Base do
  let(:authors) { create_list(:author, 5, cap_import_enabled: true) }
  let(:subclass) { Class.new(described_class) }
  let(:instance) { subclass.new }
  let(:null_logger) { Logger.new(File::NULL) }

  describe '#harvest_all' do
    it 'chunks calls to harvest based on batch_size' do
      expect { authors }.to change(Author, :count).by(5)
      expect(instance).to receive(:batch_size).once.and_return(2)
      expect(instance).to receive(:logger).exactly(5).times.and_return(null_logger)
      expect(instance).to receive(:harvest).exactly(3).times
      instance.harvest_all
    end
  end

  describe '#harvest' do
    it 'throws exception from base class' do
      expect(instance).to receive(:process_author).exactly(5).times
      instance.harvest(authors)
    end
  end

  describe '#process_author' do
    it 'throws exception from base class' do
      expect { instance.process_author(authors[0]) }.to raise_error(RuntimeError)
    end
  end
end
