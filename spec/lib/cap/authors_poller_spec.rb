describe Cap::AuthorsPoller, :vcr do
  # The author is defined in /spec/factories/author.rb
  let(:author) { create :author }
  # The publication is defined in /spec/factories/publication.rb
  let(:publication) { create :publication }
  # The contribution is defined in /spec/factories/contribution.rb
  let(:contribution) { create :contribution }

  let(:author_record) do # JSON is as defined in CAP API
    {
      'active' => author.active_in_cap,
      'authorModifiedOn' => '2016-03-25T09:11:52.000-07:00',
      'community' => 'stanford',
      'importEnabled' => true,
      'importSettings' => [
        {
          'firstName' => author.official_first_name,
          'middleName' => author.official_middle_name,
          'lastName' => author.official_last_name,
          'email' => author.email,
          'institution' => 'Stanford University',
        },
        {
          'firstName' => author.official_first_name,
          'middleName' => author.official_middle_name,
          'lastName' => author.official_last_name,
          'email' => author.email,
          'institution' => 'Some Other University',
        }
      ],
      'lastModified' => '2016-03-31T14:43:34.613-07:00',
      'populations' => ['stanford'],
      'profile' =>  {
        'displayName' => "#{author.official_first_name} #{author.official_last_name}",
        'email' => author.email,
        'names' => {
          'legal' => {
            'firstName' => author.official_first_name,
            'middleName' => author.official_middle_name,
            'lastName' => author.official_last_name,
          },
          'preferred' => {
            'firstName' => author.official_first_name,
            'middleName' => author.official_middle_name,
            'lastName' => author.official_last_name,
          }
        },
        'profileId' => author.cap_profile_id,
        'uid' => author.sunetid,
      },
      'profileId' => author.cap_profile_id
    }
  end

  let(:authorship_record) do
    # Note that this authorship record has 'sulPublicationId', whereas the
    # /authorship API specs use `sul_pub_id`.  The CAP API must be using a
    # different hash key for this field.  Either we could ask them to switch
    # over or we could modify the /authorship API parameter.  Either way, it
    # would be better for these systems to use the same key.
    author_record.merge(
      'authorship' => [
        {
          'sul_author_id' => contribution.author.id,
          'cap_profile_id' => contribution.author.cap_profile_id,
          'sulPublicationId' => contribution.publication.id,
          'featured' => contribution.featured,
          'status' => contribution.status,
          'visibility' => contribution.visibility
        }
      ]
    )
  end

  describe '#process_record' do
    before do
      # Set an instance variable that is normally set by the parent method calling #process_record
      subject.instance_variable_set('@new_or_changed_authors_to_harvest_queue', [])
    end

    context 'with an existing author' do
      before do
        expect(Author).to receive(:find_by_cap_profile_id).with(author.cap_profile_id).and_return(author)
        expect(author).to receive(:'save!').and_call_original
      end

      it 'updates an existing author' do
        expect(author).to receive(:harvestable?).and_return(true)
        expect { subject.process_record(author_record) }
          .to change { subject.instance_variable_get('@authors_updated_count') }.by(1)
      end

      it 'adds author.id to the harvest queue when harvesting is enabled' do
        expect(author).to receive(:harvestable?).and_return(true)
        queue = subject.instance_variable_get('@new_or_changed_authors_to_harvest_queue')
        expect(queue).to be_empty
        subject.process_record(author_record)
        expect(queue).to include(author.id)
      end

      it 'skips harvesting for an existing author if not marked harvestable' do
        allow(author).to receive(:changed?).and_return(true)
        expect(author).to receive(:harvestable?).and_return(false)
        expect { subject.process_record(author_record) }
          .to change { subject.instance_variable_get('@no_sw_harvest_count') }.by(1)
      end

      context 'with an authorship record' do
        it 'calls update_existing_contributions' do
          expect(subject).to receive(:update_existing_contributions).and_return(nil)
          subject.process_record(authorship_record)
        end
      end
    end

    context 'with an author retrieved from the CAP API' do
      before do
        expect(Author).to receive(:find_by_cap_profile_id).with(author.cap_profile_id).and_return(nil)
        expect(Author).to receive(:fetch_from_cap_and_create).with(author.cap_profile_id, instance_of(CapHttpClient)).and_return(author)
        expect(author).to receive(:'save!').and_return(true)
        allow(author).to receive(:new_record?).and_return(true)
      end

      it 'creates a new author' do
        expect { subject.process_record(author_record) }
          .to change { subject.instance_variable_get('@new_author_count') }.by(1)
      end

      it 'harvests for new authors marked harvestable' do
        expect(author).to receive(:harvestable?).and_return(true)
        queue = subject.instance_variable_get('@new_or_changed_authors_to_harvest_queue')
        subject.process_record(author_record)
        expect(queue).to include(author.id)
      end

      it 'skips harvests for new authors not marked harvestable' do
        expect(author).to receive(:harvestable?).and_return(false)
        expect { subject.process_record(author_record) }
          .to change { subject.instance_variable_get('@no_sw_harvest_count') }.by(1)
      end

      context 'with an authorship record' do
        it 'recognizes authorship contributions' do
          expect { subject.process_record(authorship_record) }
            .to change { subject.instance_variable_get('@new_auth_with_contribs') }.by(1)
          expect(subject).not_to receive(:update_existing_contributions)
        end
      end
    end
  end

  describe '#update_existing_contributions' do
    it 'calls update_existing_contribution' do
      expect(subject).to receive(:update_existing_contribution).and_return(nil)
      subject.update_existing_contributions(contribution.author, authorship_record['authorship'])
    end

    it 'updates an existing contribution' do
      # authorship_record['authorship'].first has data from contribution
      authorship = authorship_record['authorship'].first
      authorship['visibility'] = 'private' # was 'public'
      subject.update_existing_contributions(contribution.author, authorship_record['authorship'])
      contribution.reload
      expect(contribution.visibility).to eq(authorship['visibility'])
    end

    it 'handles when authorship is invalid submission' do
      authorship = authorship_record['authorship'].first
      expect(Contribution.valid_fields?(authorship)).to be true
      # Change the authorship so it fails to validate
      authorship.delete 'visibility'
      expect(Contribution).to receive(:valid_fields?).with(authorship).and_call_original
      # Test that an invalid authorship will generate error logging and notification
      expect(NotificationManager).to receive(:error)
      # Test that an invalid authorship will increment the counter
      count = subject.instance_variable_get('@invalid_contribs')
      subject.update_existing_contributions(contribution.author, authorship_record['authorship'])
      expect(subject.instance_variable_get('@invalid_contribs')).to eq(count + 1)
    end

    it 'handles when a contribution does not exist' do
      pubA = contribution.publication
      pubB = publication # without contribution
      # authorship_record['authorship'].first has data from contribution
      authorship = authorship_record['authorship'].first
      expect(authorship['sulPublicationId']).to eq(pubA.id)
      # Check there are no contributions for this author + pubB
      author = contribution.author
      expect(author.contributions.where(publication_id: pubB.id)).to be_empty
      # Change the sulPublicationId so it fails to find a publication contribution
      authorship['sulPublicationId'] = pubB.id
      count = subject.instance_variable_get('@contrib_does_not_exist')
      subject.update_existing_contributions(contribution.author, authorship_record['authorship'])
      expect(subject.instance_variable_get('@contrib_does_not_exist')).to eq(count + 1)
    end

    it 'handles when more than one contribution exists' do
      # Ideally, the db schema should not allow creation of more than one contribution
      # for the same author and publication.  If the schema is modified, with better
      # unique contraints on contributions, this spec should fail.  In that case,
      # it could be removed or modified to expect an exception.
      author = contribution.author
      publication = contribution.publication
      contA = contribution
      contB = create :contribution, author: author, publication: publication
      expect(author.contributions.count).to eq 2
      expect(contA.author).to eq(contB.author)
      expect(contA.publication).to eq(contB.publication)
      # authorship_record['authorship'].first has data from contribution
      authorship = authorship_record['authorship'].first
      expect(authorship['sul_author_id']).to eq(author.id)
      expect(authorship['cap_profile_id']).to eq(author.cap_profile_id)
      expect(authorship['sulPublicationId']).to eq(contA.publication.id)
      expect(authorship['sulPublicationId']).to eq(contB.publication.id)
      count = subject.instance_variable_get('@too_many_contribs')
      subject.update_existing_contributions(contribution.author, authorship_record['authorship'])
      expect(subject.instance_variable_get('@too_many_contribs')).to eq(count + 1)
    end
  end

  describe '.process_next_batch_of_authorship_data' do
    it 'handles client-server data errors' do
      expect { subject.process_next_batch_of_authorship_data(bogus: 'data') }.to raise_error(Net::HTTPBadResponse)
    end
  end
end
