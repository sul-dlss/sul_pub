# frozen_string_literal: true

describe Orcid::AddWorks do
  let(:add_works) { described_class.new(logger: logger) }

  let(:logger) { instance_double(Logger, info: nil, error: nil, warn: nil) }

  let(:orcid_user) do
    Mais::Client::OrcidUser.new(author.sunetid, author.orcidid, ['/read-limited', '/activities/update', '/person/update'],
                                '91gd29cb-124e-5bf8-1ard-90315b03ae12')
  end

  # This is an author that has no currently valid publications that can be pushed to ORCID
  let(:orcid_user_no_orcid_approved_contributions) do
    Mais::Client::OrcidUser.new(author_no_orcid_approved_contributions.sunetid, author_no_orcid_approved_contributions.orcidid,
                                ['/read-limited', '/activities/update', '/person/update'], '91gd29cb-124e-5bf8-1ard-90315b03ae12')
  end

  describe '#add_for_orcid_user' do
    let(:contribution_count) { add_works.add_for_orcid_user(orcid_user) }
    let(:contribution_count_no_orcid_approved_contributions) { add_works.add_for_orcid_user(orcid_user_no_orcid_approved_contributions) }

    let(:author) { create :author, cap_visibility: cap_visibility }
    let(:author_no_orcid_approved_contributions) { create :author, cap_visibility: cap_visibility }

    let(:cap_visibility) { 'public' }

    let(:publication) { create :pub_with_pmid_and_pub_identifier }

    let!(:contribution) { create :contribution, author: author, publication: publication }

    context 'when a user without update grant' do
      let(:orcid_user) { Mais::Client::OrcidUser.new(author.sunetid, author.orcidid, ['/read-limited'], '91gd29cb-124e-5bf8-1ard-90315b03ae12') }

      it 'skips' do
        expect(contribution_count).to be_zero
      end
    end

    context 'when Author does not exist' do
      let(:orcid_user) do
        Mais::Client::OrcidUser.new('lwittgenstein', 'https://sandbox.orcid.org/0000-0003-3437-1234', ['/read-limited', '/activities/update', '/person/update'],
                                    '91gd29cb-124e-5bf8-1ard-90315b03ae12')
      end

      it 'skips' do
        expect(contribution_count).to be_zero
      end
    end

    context 'when Author cap visibility is not public' do
      let(:cap_visibility) { 'private' }

      it 'skips' do
        expect(contribution_count).to be_zero
      end
    end

    context 'when Contribution is approved, visible, and does not have a put-code' do
      let(:client) { instance_double(Orcid::Client) }

      before do
        allow(Orcid).to receive(:client).and_return(client)
        allow(client).to receive(:add_work).and_return('1250170')
      end

      it 'adds to ORCID and updates put-code' do
        expect(contribution_count).to eq(1)

        contribution.reload
        expect(contribution.orcid_put_code).to eq('1250170')
      end
    end

    context 'when ORCID token is invalid' do
      it 'logs a warning, does not push, and does not HB' do
        create :contribution, author: author, publication: publication, status: 'approved'
        expect(NotificationManager).not_to receive(:error)
        error_message = "Orcid::AddWorks - author #{author.id} " \
                        "- did not add publication #{publication.id}: Invalid token for #{author.orcidid} " \
                        '- ORCID.org API returned 401 ' \
                        "({\n  \"error\" : \"invalid_token\",\n  \"error_description\" : \"Invalid access token: 91gd29cb-124e-5bf8-1ard-90315b03ae12\"\n})"
        expect(logger).to receive(:warn).with(error_message)
        expect(contribution_count).to be_zero
      end
    end

    context 'when pub_hash cannot be mapped to work' do
      # Default factory pub_hash is missing an identifier so allowing factory to create publication.
      let!(:contribution) { create :contribution, author: author } # rubocop:disable RSpec/LetSetup

      it 'ignores' do
        expect(NotificationManager).not_to receive(:error)
        expect(logger).to receive(:warn)
        expect(contribution_count).to be_zero
      end
    end

    context 'when Orcid client raises error' do
      let(:client) { instance_double(Orcid::Client) }

      before do
        create :contribution, author: author, publication: publication
        allow(Orcid).to receive(:client).and_return(client)
        allow(client).to receive(:add_work).and_raise('Nope!')
        allow(NotificationManager).to receive(:error)
      end

      it 'notifies' do
        expect(NotificationManager).to receive(:error).with(RuntimeError, /Nope!/, add_works)
        expect(contribution_count).to be_zero
      end
    end

    context 'when Contribution is not approved' do
      it 'skips' do
        create :contribution, author: author_no_orcid_approved_contributions, publication: publication, status: 'new'
        expect(logger).not_to receive(:warn)
        expect(contribution_count_no_orcid_approved_contributions).to be_zero
      end
    end

    context 'when Contribution is not public' do
      before do
        create :contribution, author: author_no_orcid_approved_contributions, publication: publication, visibility: 'private'
      end

      it 'skips' do
        expect(logger).not_to receive(:warn)
        expect(contribution_count_no_orcid_approved_contributions).to be_zero
      end
    end

    context 'when Contribution already has put-code' do
      before do
        create :contribution, author: author_no_orcid_approved_contributions, publication: publication, orcid_put_code: '1250170'
      end

      it 'skips' do
        expect(logger).not_to receive(:warn)
        expect(contribution_count_no_orcid_approved_contributions).to be_zero
      end
    end
  end

  describe '#add_all' do
    let(:contribution_count) { add_works.add_all(orcid_users) }

    let(:orcid_users) do
      [
        Mais::Client::OrcidUser.new('dkahneman', 'https://sandbox.orcid.org/0000-0003-3437-1234', ['/read-limited', '/activities/update', '/person/update'],
                                    '91gd29cb-124e-5bf8-1ard-90315b03ae12'),
        Mais::Client::OrcidUser.new('atversky', 'https://sandbox.orcid.org/0000-0003-3437-5678', ['/read-limited', '/activities/update', '/person/update'],
                                    '91gd29cb-124e-5bf8-1ard-90315b03ae13')
      ]
    end

    before do
      allow(add_works).to receive(:add_for_orcid_user).and_return(1, 5)
    end

    it 'calls add_for_orcid_user' do
      expect(add_works).to receive(:add_for_orcid_user).twice

      expect(contribution_count).to eq(6)
    end
  end
end
