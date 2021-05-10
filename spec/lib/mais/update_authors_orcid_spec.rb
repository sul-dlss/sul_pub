# frozen_string_literal: true

describe Mais::UpdateAuthorsOrcid do
  let(:update_authors_orcid) { described_class.new(orcid_users, logger: logger) }

  let!(:author_with_existing_orcid) { create :author }
  let!(:author_with_no_orcid) { create :author, orcidid: nil }
  let(:logger) { instance_double(Logger, info: nil) }

  describe '#update' do
    context 'when updating or adding to existing' do
      let(:orcid_users) do
        [
          Mais::Client::OrcidUser.new(author_with_existing_orcid.sunetid, 'https://orcid.org/0000-0000-0000-0000'),
          Mais::Client::OrcidUser.new(author_with_no_orcid.sunetid, 'https://orcid.org/0000-0000-0000-0001'),
          Mais::Client::OrcidUser.new('DOES NOT EXIST', 'https://orcid.org/0000-0000-0000-0001')
        ]
      end

      it 'updates orcid' do
        expect(logger).to receive(:info).with(%r{updating orcid id to https://orcid.org/0000-0000-0000-0001})

        expect(update_authors_orcid.update).to eq(2)

        author_with_existing_orcid.reload
        expect(author_with_existing_orcid.orcidid).to eq('https://orcid.org/0000-0000-0000-0000')

        author_with_no_orcid.reload
        expect(author_with_no_orcid.orcidid).to eq('https://orcid.org/0000-0000-0000-0001')
      end
    end
  end

  context 'when removing existing' do
    let(:orcid_users) { [] }

    it 'removes orcid' do
      expect(update_authors_orcid.update).to eq(1)

      author_with_existing_orcid.reload
      expect(author_with_existing_orcid.orcidid).to eq(nil)

      author_with_no_orcid.reload
      expect(author_with_no_orcid.orcidid).to eq(nil)
    end
  end
end
