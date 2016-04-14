require 'spec_helper'

describe ScienceWire::Request do
  describe '#initialize' do
    it 'requires keyword arguments' do
      expect { subject }.to raise_error(
        ArgumentError, 'missing keyword: client'
      )
    end
  end
  describe '#perform' do
    let(:client) do
      ScienceWire::Client.new(
        licence_id: 'license', host: Settings.SCIENCEWIRE.HOST
      )
    end
    subject { described_class.new(client: {}) }
    it 'receives the response and calls the body' do
      expect(subject).to receive(:response).and_return double body: ''
      subject.perform
    end
    it 'creates a request' do
      stub_post('/not_a_real_path').with(query: {format: 'xml'})
      described_class.new(client: client, path: '/not_a_real_path').perform
      expect(a_post('/not_a_real_path').with(headers: {
        'Content-Type' => 'text/xml',
        'Expect' => '100-continue',
        'Host' => Settings.SCIENCEWIRE.HOST,
        'Licenseid' => 'license'
      })).to have_been_made
    end
  end
end
