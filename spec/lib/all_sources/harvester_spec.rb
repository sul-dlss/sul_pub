# frozen_string_literal: true

describe AllSources::Harvester do
  let(:harvester) { described_class.new }

  describe '#process_author' do
    let(:options) { { some_options: 'here' } }
    let(:author) { create(:author) }

    context 'wos and pubmed enabled' do
      it 'calls both pubmed and wos harvester for the author' do
        allow(Settings.WOS).to receive(:enabled).and_return(true)
        allow(Settings.PUBMED).to receive(:harvest_enabled).and_return(true)
        expect(WebOfScience.harvester).to receive(:process_author).with(author, options)
        expect(Pubmed.harvester).to receive(:process_author).with(author, options)
        harvester.process_author(author, options)
      end
    end

    context 'wos disabled' do
      it 'calls only the pubmed harvester for the author' do
        allow(Settings.WOS).to receive(:enabled).and_return(false)
        allow(Settings.PUBMED).to receive(:harvest_enabled).and_return(true)
        expect(WebOfScience.harvester).not_to receive(:process_author).with(author, options)
        expect(Pubmed.harvester).to receive(:process_author).with(author, options)
        harvester.process_author(author, options)
      end
    end

    context 'pubmed disabled' do
      it 'calls only the wos harvester for the author' do
        allow(Settings.WOS).to receive(:enabled).and_return(true)
        allow(Settings.PUBMED).to receive(:harvest_enabled).and_return(false)
        expect(WebOfScience.harvester).to receive(:process_author).with(author, options)
        expect(Pubmed.harvester).not_to receive(:process_author).with(author, options)
        harvester.process_author(author, options)
      end
    end
  end
end
