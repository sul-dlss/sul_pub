# frozen_string_literal: true

describe Orcid::DeleteWorks do
  let(:delete_works) { described_class.new(logger:) }

  let(:logger) { instance_double(Logger, info: nil) }

  let(:orcid_user) do
    Mais::Client::OrcidUser.new(author.sunetid, author.orcidid, ['/read-limited', '/activities/update', '/person/update'],
                                '91gd29cb-124e-5bf8-1ard-90315b03ae12')
  end

  describe '#delete_work' do
    let(:work_deleted) { delete_works.delete_work(contribution, orcid_user) }

    let(:author) { create :author }

    let(:publication) { create :pub_with_pmid_and_pub_identifier }

    let(:put_code) { '1253255' }

    let(:contribution) { create :contribution, author:, publication:, orcid_put_code: put_code }

    context 'when a user without update grant' do
      let(:orcid_user) { Mais::Client::OrcidUser.new(author.sunetid, author.orcidid, ['/read-limited'], '91gd29cb-124e-5bf8-1ard-90315b03ae12') }

      it 'skips' do
        expect(work_deleted).to be false
      end
    end

    context 'when Author does not exist' do
      let(:orcid_user) do
        Mais::Client::OrcidUser.new('lwittgenstein', 'https://sandbox.orcid.org/0000-0003-3437-1234', ['/read-limited', '/activities/update', '/person/update'],
                                    '91gd29cb-124e-5bf8-1ard-90315b03ae12')
      end

      it 'skips' do
        expect(work_deleted).to be false
      end
    end

    context 'when Contribution has a put-code' do
      let(:client) { instance_double(Orcid::Client) }

      before do
        allow(Orcid).to receive(:client).and_return(client)
        allow(client).to receive(:delete_work).and_return(true)
      end

      it 'deletes work and nils put-code' do
        expect(client).to receive(:delete_work).with(author.orcidid, put_code, '91gd29cb-124e-5bf8-1ard-90315b03ae12')
        expect(work_deleted).to be true

        contribution.reload
        expect(contribution.orcid_put_code).to be_nil
      end
    end

    context 'when Orcid work does not exist' do
      let(:client) { instance_double(Orcid::Client) }

      before do
        allow(Orcid).to receive(:client).and_return(client)
        allow(client).to receive(:delete_work).and_return(false)
      end

      it 'handles the 404 without raising and nils put-code' do
        expect(client).to receive(:delete_work).with(author.orcidid, put_code, '91gd29cb-124e-5bf8-1ard-90315b03ae12')
        expect(work_deleted).to be false

        contribution.reload
        expect(contribution.orcid_put_code).to be_nil
      end
    end

    context 'when Orcid client raises error' do
      let(:client) { instance_double(Orcid::Client) }

      before do
        create :contribution, author:, publication:, orcid_put_code: put_code
        allow(Orcid).to receive(:client).and_return(client)
        allow(client).to receive(:delete_work).and_raise('Nope!')
        allow(NotificationManager).to receive(:error)
      end

      it 'notifies' do
        expect(NotificationManager).to receive(:error).with(RuntimeError, /Nope!/, delete_works)
        expect(work_deleted).to be false
      end
    end
  end

  describe '#delete_for_orcid_user' do
    let(:contribution_count) { delete_works.delete_for_orcid_user(orcid_user) }

    let(:author) { create :author }

    before do
      create :contribution, author:, orcid_put_code: '1250172'
      create :contribution, author:, orcid_put_code: '1250173'
      create :contribution, author:, orcid_put_code: '1250174'
      allow(delete_works).to receive(:delete_work).and_return(true, false, true)
    end

    it 'calls add_for_orcid_user' do
      expect(delete_works).to receive(:delete_work).exactly(3).times

      expect(contribution_count).to eq(2)
    end
  end
end
