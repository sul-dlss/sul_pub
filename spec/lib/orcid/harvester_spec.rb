# frozen_string_literal: true

describe Orcid::Harvester do
  let(:logger) { instance_double(Logger, info: nil) }
  let(:author) { create :author, orcidid: orcid_id, orcid_last_modified: 1_607_403_656_707 }
  let(:orcid_id) { 'https://sandbox.orcid.org/0000-0003-3437-349X' }
  let(:put_code) { '73980892' }
  let(:base_works_response) do
    {
      'last-modified-date': {
        value: 1_607_403_600_000
      },
      group: [
        {
          'work-summary': [
            work_response,
            {
              title: {
                title: {
                  value: 'This work summary is not used.'
                }
              }
            }
          ]
        }
      ]
    }
  end
  let(:works_response) { base_works_response }
  let(:base_work_response) do
    {
      'put-code': put_code,
      'last-modified-date': {
        value: 1_607_403_656_707
      },
      title: {
        title: {
          value: 'Minds, Brains and Programs'
        }
      },
      'external-ids': {
        'external-id': [
          {
            'external-id-value': '10.1017/S0140525X00005756',
            'external-id-type': 'doi',
            'external-id-relationship': 'self',
            'external-id-url': 'https://doi.org/10.1017/S0140525X00005756'
          }
        ]
      },
      type: work_type
    }
  end
  let(:work_response) { base_work_response }
  let(:work_type) { 'journal-article' }
  let(:client) { instance_double(Orcid::Client) }

  before do
    allow(Orcid).to receive(:logger).and_return(logger)
    allow(Orcid).to receive(:client).and_return(client)
    allow(client).to receive(:fetch_works).and_return(works_response.with_indifferent_access)
    allow(client).to receive(:fetch_work).and_return(work_response.with_indifferent_access)
  end

  describe '#process_author' do
    let(:harvester) { described_class.new }
    let(:put_codes) { harvester.process_author(author) }

    context 'when Author does not have orcid id' do
      let(:orcid_id) { nil }

      it 'skips' do
        expect(client).not_to receive(:fetch_works)

        expect(put_codes).to be_empty
      end
    end

    context 'when no changes' do
      let(:works_response) do
        {
          'last-modified-date': {
            value: 1_607_403_656_707
          }
        }
      end

      it 'skips' do
        expect(client).to receive(:fetch_works).with(orcid_id)

        expect(put_codes).to be_empty
      end
    end

    context 'when work type is not supported' do
      let(:work_type) { 'dance' }

      it 'skips' do
        expect(put_codes).to be_empty
      end
    end

    context 'when no self external identifiers' do
      let(:works_response) do
        base_works_response.dup.tap do |works_response|
          works_response[:group].first[:'work-summary'].first[:'external-ids'][:'external-id'].first[:'external-id-relationship'] = 'part-of'
        end
      end

      it 'skips' do
        expect(put_codes).to be_empty
      end
    end

    context 'when only ISSN external identifiers' do
      let(:works_response) do
        base_works_response.dup.tap do |works_response|
          works_response[:group].first[:'work-summary'].first[:'external-ids'][:'external-id'].first[:'external-id-type'] = 'issn'
        end
      end

      it 'skips' do
        expect(put_codes).to be_empty
      end
    end

    context 'when harvesting fails' do
      before do
        allow(client).to receive(:fetch_works).and_raise('Wrong!')
      end

      it 'notifies' do
        expect(NotificationManager).to receive(:error).with(StandardError, /Orcid.org harvest failed/, harvester)
        expect(put_codes).to be_empty
      end
    end

    context 'when Publication exists and Author is associated' do
      let!(:publication) do
        pub = Publication.create
        PublicationIdentifier.create(publication: pub, identifier_type: 'doi', identifier_value: '10.1017/S0140525X00005756')
        Contribution.create(publication: pub, author: author)
        pub
      end

      it 'Updates author' do
        expect(client).not_to receive(:fetch_work)
        expect(publication.contributions.size).to eq(1)

        expect(put_codes).to eq([put_code])

        # No OrcidSourceRecord
        expect(OrcidSourceRecord.find_by(put_code: put_code, orcidid: orcid_id)).to be_nil

        # And contribution
        publication.reload
        expect(publication.contributions.size).to eq(1)

        # Updates Author
        expect(author.orcid_last_modified).to eq(1_607_403_600_000)
      end
    end

    context 'when Publication exists and Author is not associated' do
      let!(:publication) do
        pub = Publication.create
        PublicationIdentifier.create(publication: pub, identifier_type: 'doi', identifier_value: '10.1017/S0140525X00005756')
        pub
      end

      it 'Creates Contribution and updates Author' do
        expect(client).not_to receive(:fetch_work)
        expect(publication.contributions.size).to eq(0)

        expect(put_codes).to eq([put_code])

        # No OrcidSourceRecord
        expect(OrcidSourceRecord.find_by(put_code: put_code, orcidid: orcid_id)).to be_nil

        # And contribution
        publication.reload
        expect(publication.contributions.size).to eq(1)
        contribution = publication.contributions.first
        expect(contribution.author).to eq(author)

        # Updates Author
        expect(author.orcid_last_modified).to eq(1_607_403_600_000)
      end
    end

    context 'when Publication does not exist' do
      it 'creates and updates entities and returns put-codes' do
        expect(client).to receive(:fetch_work).with(orcid_id, put_code)

        expect(put_codes).to eq([put_code])

        # Creates OrcidSourceRecord
        source_record = OrcidSourceRecord.find_by(put_code: put_code, orcidid: orcid_id)
        expect(source_record.last_modified_date).to eq(1_607_403_656_707)
        expect(source_record.source_fingerprint).to start_with('392909bbb07')
        expect(source_record.source_data.with_indifferent_access).to match(work_response)

        # Creates Publication
        publication = source_record.publication
        expect(publication.title).to eq('Minds, Brains and Programs')
        expect(publication.active).to eq(true)
        expect(publication.pub_hash).to be_present

        # With Identifiers
        expect(publication.publication_identifiers.size).to eq(1)
        identifier = publication.publication_identifiers.first
        expect(identifier.identifier_type).to eq('doi')
        expect(identifier.identifier_value).to eq('10.1017/S0140525X00005756')
        expect(identifier.identifier_uri).to eq('https://doi.org/10.1017/S0140525X00005756')

        # And contribution
        expect(publication.contributions.size).to eq(1)
        contribution = publication.contributions.first
        expect(contribution.author).to eq(author)
        expect(contribution.orcid_put_code).to eq(put_code)

        # Updates Author
        expect(author.orcid_last_modified).to eq(1_607_403_600_000)
      end
    end

    context 'when Publication exists with same ISSN' do
      let(:work_response) do
        base_work_response.dup.tap do |work_response|
          work_response[:'external-ids'][:'external-id'] << {
            'external-id-value': '1432-5012',
            'external-id-type': 'issn',
            'external-id-relationship': 'self',
            'external-id-url': nil
          }
        end
      end

      before do
        pub = Publication.create
        PublicationIdentifier.create(publication: pub, identifier_type: 'issn', identifier_value: '1432-5012')
      end

      it 'does not match existing publication' do
        expect(client).to receive(:fetch_work).with(orcid_id, put_code)

        expect(put_codes).to eq([put_code])

        # Creates OrcidSourceRecord
        source_record = OrcidSourceRecord.find_by(put_code: put_code, orcidid: orcid_id)

        # Creates Publication
        publication = source_record.publication
        expect(publication.title).to eq('Minds, Brains and Programs')
      end
    end
  end
end
