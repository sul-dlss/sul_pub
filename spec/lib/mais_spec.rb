# frozen_string_literal: true

describe Mais do
  describe '#working' do
    context 'when working' do
      let(:client) { instance_double(Mais::Client, fetch_orcid_users: ['FAKE_ORCID_USER']) }

      before do
        allow(Mais::Client).to receive(:new).and_return(client)
      end

      it 'returns true' do
        expect(described_class.working?).to be(true)
      end
    end

    context 'when not working' do
      let(:client) { instance_double(Mais::Client) }

      before do
        allow(Mais::Client).to receive(:new).and_return(client)
        allow(client).to receive(:fetch_orcid_users).and_raise(StandardError, 'Fail!')
      end

      it 'returns false' do
        expect(described_class.working?).to be(false)
      end
    end
  end
end
