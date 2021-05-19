# frozen_string_literal: true

describe Orcid do
  describe '#working' do
    context 'when working' do
      it 'returns true' do
        VCR.use_cassette('Orcid_Client/_fetch_works/retrieves works summary') do
          expect(described_class.working?).to be(true)
        end
      end
    end

    context 'when not working' do
      it 'returns false' do
        VCR.use_cassette('Orcid_Client/_fetch_works/raises') do
          expect(described_class.working?).to be(false)
        end
      end
    end
  end
end
