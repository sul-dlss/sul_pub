# frozen_string_literal: true

describe Orcid::Client do
  let(:subject) { described_class.new }

  describe '#fetch_works' do
    let(:works_response) { subject.fetch_works('https://orcid.org/0000-0003-1527-0030') }

    it 'retrieves works summary' do
      VCR.use_cassette('Orcid_Client/_fetch_works/retrieves works summary') do
        expect(works_response[:group].size).to eq(36)
      end
    end

    context 'when server returns 500' do
      it 'raises' do
        VCR.use_cassette('Orcid_Client/_fetch_works/raises') do
          expect { works_response }.to raise_error('ORCID.org API returned 500')
        end
      end
    end
  end
end
