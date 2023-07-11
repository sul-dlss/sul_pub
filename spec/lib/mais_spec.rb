# frozen_string_literal: true

describe Mais do
  describe '#working' do
    context 'when working' do
      before do
        allow(MaisOrcidClient).to receive(:fetch_orcid_users).and_return(['FAKE_ORCID_USER'])
      end

      it 'returns true' do
        expect(described_class.working?).to be(true)
      end
    end

    context 'when not working' do
      before do
        allow(MaisOrcidClient).to receive(:fetch_orcid_users).and_raise(StandardError, 'Fail!')
      end

      it 'returns false' do
        expect(described_class.working?).to be(false)
      end
    end
  end
end
