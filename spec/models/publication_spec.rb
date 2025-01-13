# frozen_string_literal: true

describe Publication do
  let(:publication) { create(:publication) }
  let(:author) { create(:author) }

  let(:pub_hash) do
    {
      title: 'some title',
      year: '1938',
      issn: '32242424',
      pages: '34-56',
      author: [{ name: 'jackson joe' }],
      authorship: [{ sul_author_id: author.id, status: 'denied', visibility: 'public', featured: true }],
      identifier: [{ type: 'x', id: 'y', url: 'z' }],
      type: 'article'
    }
  end

  let(:pub_hash_cap_authorship) do
    # This input simulates a manual publication submission for an author who is
    # not yet in the SULCAP authors table, so there is no `author.id`.
    pub_hash.merge authorship: [{
      cap_profile_id: 29_091,
      status: 'approved',
      visibility: 'public',
      featured: true
    }]
  end

  describe '.pubhash_needs_update' do
    subject(:pub) { described_class.new(pubhash_needs_update: true) }

    it 'allows initialization with pubhash_needs_update' do
      expect(pub.pubhash_needs_update).to be true
    end
  end

  describe 'pub_hash validation' do
    subject { described_class.create!(pub_hash:) }

    it 'notifies HB but does not fail validation on invalid pub_hash' do
      expect(Honeybadger).to receive(:notify).with(
        '[PUB_HASH VALIDATION ERROR]',
        { context: { message: ['/title with value  is invalid for schema: /properties/title'],
                     publication_id: subject.id } }
      )
      subject.pub_hash[:title] = nil
      expect(subject.save).to be true
    end

    it 'does not notify HB on valid pub_hash' do
      expect(Honeybadger).not_to receive(:notify)
      expect(subject.save).to be true
    end
  end

  describe 'test pub hash syncing for new object' do
    subject { described_class.create!(pub_hash:) }

    it 'rebuilds identifiers' do
      expect(subject.pub_hash[:identifier].length).to be > 0
      expect(subject.pub_hash[:sulpubid]).to eq(subject.id.to_s)
      expect(subject.pub_hash[:identifier]).to include(type: 'SULPubId', id: subject.id.to_s,
                                                       url: "#{Settings.SULPUB_ID.PUB_URI}/#{subject.id}")
      expect(subject.pub_hash[:identifier]).not_to include(type: 'SULPubId', url: "#{Settings.SULPUB_ID.PUB_URI}/")
      expect(subject.pub_hash[:identifier]).to include(type: 'x', id: 'y', url: 'z')
    end
  end

  describe 'pubhash syncing' do
    context 'author exists in authors table' do
      subject do
        expect(Author).to receive(:find_by_id).and_return(author)
        publication.pub_hash = pub_hash.dup
        publication.send(:update_any_new_contribution_info_in_pub_hash_to_db)
        publication.save!
        publication.reload
      end

      it 'sets the last updated value to match the database row' do
        expect(Time.zone.parse(subject.pub_hash[:last_updated])).to be >= 1.minute.ago
      end

      it 'rebuilds authors' do
        expect(subject.contributions.entries.size).to eq(1)
        expect(subject.pub_hash[:authorship].length).to be > 0
        expect(subject.pub_hash[:authorship]).to include(subject.contributions.first.to_pub_hash)
      end

      it 'rebuilds identifiers' do
        expect(subject.pub_hash[:identifier].length).to be > 0
        expect(subject.pub_hash[:sulpubid]).to eq(subject.id.to_s)
        expect(subject.pub_hash[:identifier]).to include(type: 'SULPubId', id: subject.id.to_s,
                                                         url: "#{Settings.SULPUB_ID.PUB_URI}/#{subject.id}")
        expect(subject.pub_hash[:identifier]).to include(type: 'x', id: 'y', url: 'z')
      end
    end

    context 'author does not yet exist in authors table' do
      subject do
        expect(Author).to receive(:find_by_cap_profile_id).and_return(nil)
        expect(Author).to receive(:fetch_from_cap_and_create).and_return(author)
        publication.pub_hash = pub_hash_cap_authorship.dup
        publication.send(:update_any_new_contribution_info_in_pub_hash_to_db)
        publication.save!
        publication.reload
      end

      it 'rebuilds authors' do
        expect(subject.contributions.entries.size).to eq(1)
        expect(subject.pub_hash[:authorship].length).to be > 0
        expect(subject.pub_hash[:authorship]).to include(subject.contributions.first.to_pub_hash)
      end
    end

    context 'author does not exist and cannot be retrieved from CAP API' do
      let(:logger) { Logger.new(File::NULL) }

      it 'logs errors' do
        expect(Author).to receive(:find_by_cap_profile_id).and_return(nil)
        expect(Author).to receive(:fetch_from_cap_and_create).and_raise(NoMethodError)
        expect(NotificationManager).to receive(:cap_logger).once.and_return(logger)
        expect(logger).to receive(:error).exactly(3)
        publication.pub_hash = pub_hash_cap_authorship.dup
        publication.send(:update_any_new_contribution_info_in_pub_hash_to_db)
      end
    end
  end

  describe 'sync_identifiers_in_pub_hash' do
    let(:pub_xyz) do
      publication.pub_hash = pub_hash.merge(identifier: [{ type: 'x', id: 'y', url: 'z' }])
      publication.send(:sync_identifiers_in_pub_hash)
      publication.save!
      publication
    end

    it 'syncs identifiers in the pub hash to the database' do
      expect(pub_xyz.publication_identifiers.reload)
        .to include(PublicationIdentifier.find_by(identifier_type: 'x', identifier_value: 'y'))
    end

    it 'does not persist SULPubIds' do
      publication.pub_hash = pub_hash.merge(identifier: [{ type: 'SULPubId', id: 'y', url: 'z' }])
      expect do
        publication.send(:sync_identifiers_in_pub_hash)
        publication.save!
      end.not_to change(publication, :publication_identifiers)
    end

    it 'updates existing ids with new values' do
      pub_xyz.pub_hash = pub_hash.merge(identifier: [{ type: 'x', id: 'y2', url: 'z2' }])
      pub_xyz.send(:sync_identifiers_in_pub_hash)
      pub_xyz.save!
      ids = PublicationIdentifier.where(publication_id: pub_xyz.id).all
      expect(ids.size).to eq(1)
      expect(ids.first.identifier_type).to eq('x')
      expect(ids.first.identifier_value).to eq('y2')
      expect(ids.first.identifier_uri).to eq('z2')
    end

    it 'avoids writing back empty values' do # stop our bad data from spreading
      pub_xyz.pub_hash = pub_hash.merge(identifier: [{ type: 'x', id: nil, url: 'z2' }, { type: 'q', id: nil, url: 'z2' }])
      pub_xyz.send(:sync_identifiers_in_pub_hash)
      pub_xyz.save!
      ids = PublicationIdentifier.where(publication_id: pub_xyz.id).all
      expect(ids.size).to eq(1)
      expect(ids.first.identifier_type).to eq('x')
      expect(ids.first.identifier_value).to eq('y')
      expect(ids.first.identifier_uri).to eq('z')
    end

    it 'deletes ids from the database that are not longer in the pub_hash' do
      pub_xyz.pub_hash = pub_hash.merge(identifier: [{ type: 'a', id: 'b', url: 'c' }])
      pub_xyz.send(:sync_identifiers_in_pub_hash)
      pub_xyz.save!
      expect(PublicationIdentifier.where(publication_id: pub_xyz.id, identifier_type: 'x').count).to eq(0)
      expect(PublicationIdentifier.where(publication_id: pub_xyz.id, identifier_type: 'a').count).to eq(1)
    end

    it 'does not delete legacy_cap_pub_id when missing from the incoming pub_hash' do
      publication.pub_hash = pub_hash.merge(identifier: [{ type: 'legacy_cap_pub_id', id: '258214' }])
      publication.send(:sync_identifiers_in_pub_hash)
      publication.save!
      publication.pub_hash = pub_hash.merge(identifier: [{ type: 'another', id: 'id', url: 'with a url' }])
      publication.send(:sync_identifiers_in_pub_hash)
      publication.save!
      expect(PublicationIdentifier.where(publication_id: publication.id,
                                         identifier_type: 'legacy_cap_pub_id').count).to eq(1)
      expect(PublicationIdentifier.where(publication_id: publication.id, identifier_type: 'another').count).to eq(1)
    end
  end

  describe 'update_any_new_contribution_info_in_pub_hash_to_db' do
    it 'syncs existing authors in the pub hash to contributions in the db' do
      publication.pub_hash = pub_hash.merge(authorship: [{ status: 'new', sul_author_id: author.id }])
      publication.send(:update_any_new_contribution_info_in_pub_hash_to_db)
      expect(publication.contributions.size).to eq(1)
      c = publication.contributions.last
      expect(c.author).to eq(author)
      expect(c.status).to eq('new')
    end

    it 'downcases status and visibility values' do
      publication.pub_hash = pub_hash.merge(authorship: [{ status: 'NEW', sul_author_id: author.id, visibility: 'PUBLIC' }])
      publication.send(:update_any_new_contribution_info_in_pub_hash_to_db)
      c = publication.contributions.last
      expect(c.status).to eq('new')
      expect(c.visibility).to eq('public')
    end

    it 'updates attributions of existing contributions to the database' do
      expect(publication.contributions.size).to eq(0)
      publication.contributions.create(author:, cap_profile_id: author.cap_profile_id, status: 'unknown')
      publication.pub_hash = pub_hash.merge(authorship: [{ status: 'new', sul_author_id: author.id }])
      publication.send(:update_any_new_contribution_info_in_pub_hash_to_db)
      expect(publication.contributions.size).to eq(1)
      c = publication.contributions.reload.last
      expect(c.author).to eq(author)
      expect(c.status).to eq('new')
    end

    it 'looks up authors by their cap profile id' do
      author.cap_profile_id = 'abc'
      author.save!
      publication.pub_hash = pub_hash.merge(authorship: [{ status: 'new', cap_profile_id: author.cap_profile_id, featured: false, visibility: 'private' }])
      publication.send(:update_any_new_contribution_info_in_pub_hash_to_db)

      publication.save!
      expect(publication.contributions.size).to eq(1)
      c = publication.contributions.last
      expect(c.author).to eq(author)
      expect(c.status).to eq('new')
    end

    it 'ignores unknown authors' do
      publication.pub_hash = pub_hash.merge(authorship: [{ status: 'unknown', cap_profile_id: 0, featured: false, visibility: 'private' }])
      publication.send(:update_any_new_contribution_info_in_pub_hash_to_db)
      publication.save!
      expect(publication.contributions).to be_empty
    end
  end

  describe 'add_any_pubmed_data_to_hash' do
    let(:pubmed_src_record) { PubmedSourceRecord.new }

    context 'when a Pubmed Record exists' do
      before do
        allow(PubmedSourceRecord).to receive(:for_pmid).with(1).and_return pubmed_src_record
      end

      it 'adds mesh and abstract data if available' do
        publication.pmid = 1
        allow(pubmed_src_record).to receive(:source_as_hash).and_return mesh_headings: 'x', abstract: 'y',
                                                                        identifier: [{ type: 'PMID', id: publication.pmid, url: "#{Settings.PUBMED.ARTICLE_BASE_URI}#{publication.pmid}" }]
        publication.send(:add_any_pubmed_data_to_hash)
        expect(publication.pub_hash[:mesh_headings]).to eq('x')
        expect(publication.pub_hash[:abstract]).to eq('y')
      end

      it 'ignores records without a pmid' do
        expect(PubmedSourceRecord).not_to receive(:for_pmid)
        publication.send(:add_any_pubmed_data_to_hash)
      end

      it 'adds pmcid if available' do
        publication.pmid = 1
        allow(pubmed_src_record).to receive(:source_as_hash).and_return(identifier: [{ type: 'pmc', id: '123456' }])
        publication.send(:add_any_pubmed_data_to_hash)
        expect(publication.pub_hash[:identifier].include?(type: 'pmc', id: '123456')).to be true
      end

      it 'does not add pmcid if not available' do
        publication.pmid = 1
        allow(pubmed_src_record).to receive(:source_as_hash).and_return(identifier: [{
                                                                          type: 'some_odd_non_supported_type', id: '123456'
                                                                        }])
        publication.send(:add_any_pubmed_data_to_hash)
        expect(publication.pub_hash[:identifier].include?(type: 'pmc', id: '123456')).to be false # no pmcid and no exception either
        expect(publication.pub_hash[:identifier].include?(type: 'some_odd_non_supported_type', id: '123456')).to be false # this one ain't there either
      end
    end

    it 'ignores records with an empty pubmed record' do
      publication.pmid = 1
      allow(PubmedSourceRecord).to receive(:for_pmid).with(1).and_return nil
      expect(PubmedSourceRecord).to receive(:for_pmid).with(1)
      publication.send(:add_any_pubmed_data_to_hash)
    end
  end

  describe 'delete!' do
    it 'marks the publication deleted' do
      publication.delete!
      expect(publication.deleted).to be_truthy
      expect(publication).to be_deleted
    end
  end

  describe 'pubhash_needs_update' do
    it 'marks the pub hash as modified' do
      publication.pubhash_needs_update!
      expect(publication).to be_pubhash_needs_update
    end
  end

  describe 'update_from_pubmed' do
    let(:pmid) { 1 }

    it 'does not update from pubmed source if there is no pmid' do
      expect(publication.pmid).to be_nil
      expect(publication.update_from_pubmed).to be false
    end

    it 'does not update from pubmed source if not a pubmed source record' do
      publication.pub_hash[:provenance] = 'cap'
      expect(publication.update_from_pubmed).to be false
    end

    it 'does not update from pubmed source if it is not pubmed provenance' do
      expect(publication.pmid).to be_nil
      expect(publication.pub_hash[:provenance]).not_to be 'pubmed'
      expect(publication.update_from_pubmed).to be false
    end

    it 'updates from pubmed source if there is a pmid and it is pubmed provenance' do
      publication.pmid = pmid
      publication.pub_hash[:provenance] = 'pubmed'
      source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><OriginalData/><Article><ArticleTitle>How I learned Rails</ArticleTitle></Article></PubmedArticle>'
      new_source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><Article><ArticleTitle>How I learned Rails</ArticleTitle></Article><PMID Version="1">123</PMID><SomeNewData/></PubmedArticle>'
      pubmed_record = PubmedSourceRecord.create(pmid:, source_data:)
      allow(PubmedSourceRecord).to receive(:find_by_pmid).with(pmid).and_return(pubmed_record)
      expect(pubmed_record.source_data).to be_equivalent_to source_data
      allow_any_instance_of(Pubmed::Client).to receive(:fetch_records_for_pmid_list).with(pmid).and_return(new_source_data)
      expect(publication.pub_hash[:title]).to eq 'How I learned Rails'
      expect(publication.pub_hash[:identifier]).to eq(
        [
          { type: 'SULPubId', id: publication.id.to_s,
            url: "http://sulcap.stanford.edu/publications/#{publication.id}" }
        ]
      )
      expect(publication.pmid).not_to be_nil
      expect(publication.update_from_pubmed).to be true
      expect(publication.pub_hash[:title]).to eq 'How I learned Rails'
      expect(publication.pub_hash[:identifier]).to eq(
        [
          { type: 'PMID', id: '123', url: 'https://www.ncbi.nlm.nih.gov/pubmed/123' },
          { type: 'SULPubId', id: publication.id.to_s,
            url: "http://sulcap.stanford.edu/publications/#{publication.id}" }
        ]
      )
      expect(PubmedSourceRecord.find_by_pmid(pmid).source_data).to be_equivalent_to new_source_data
    end
  end

  describe 'update_formatted_citations' do
    before do
      cite = Csl::Citation.new({})
      allow(cite).to receive_messages(to_apa_citation: 'apa', to_mla_citation: 'mla', to_chicago_citation: 'chicago')
      allow(Csl::Citation).to receive(:new).and_return(cite)
    end

    it 'update the APA citation' do
      publication.pub_hash[:apa_citation] = 'before'
      expect { publication.update_formatted_citations }.to change { publication.pub_hash[:apa_citation] }
    end

    it 'update the MLA citation' do
      publication.pub_hash[:mla_citation] = 'before'
      expect { publication.update_formatted_citations }.to change { publication.pub_hash[:mla_citation] }
    end

    it 'update the Chicago citation' do
      publication.pub_hash[:chicago_citation] = 'before'
      expect { publication.update_formatted_citations }.to change { publication.pub_hash[:chicago_citation] }
    end
  end

  describe '.build_new_manual_publication' do
    let(:save_new_publication) do
      pub = described_class.build_new_manual_publication(pub_hash, 'some string')
      pub.save!
      pub
    end

    it 'adds a publication with one author' do
      pub = save_new_publication
      expect(pub.authors.size).to eq(1)
      expect(pub.pub_hash[:authorship].size).to eq(1)
    end

    it 'refuses to add a publication with the same source record' do
      save_new_publication
      expect do
        described_class.build_new_manual_publication(pub_hash, 'some string')
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "creates a publication if a publication for that source record doesn't exist" do
      UserSubmittedSourceRecord.create!(source_data: 'some string')
      expect { save_new_publication }.not_to raise_exception
    end
  end

  describe 'update_manual_pub_from_pub_hash' do
    let(:pub) { described_class.build_new_manual_publication({ title: 'b', type: 'article' }, 'some string') }

    it 'updates the user submitted source record with the new content' do
      expect(pub.user_submitted_source_records.first[:source_data]).to eq('some string')
      pub.update_manual_pub_from_pub_hash({ date: '2020', type: 'article' }, 'some other string')
      pub.save!
      expect(pub.user_submitted_source_records.first[:source_data]).to eq('some other string')
      expect(pub.pub_hash).to include(date: '2020')
    end

    it 'raises an exception if you try to update an existing publication record to match an existing user submitted source record' do
      pub.save!
      other = described_class.build_new_manual_publication({ title: 'c', type: 'article' }, 'some other string')
      other.update_manual_pub_from_pub_hash({ title: 'c', type: 'article' }, 'some string')
      expect { other.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'does not alter the hash provided' do
      h = { pub: 'hash' }
      expect { pub.update_manual_pub_from_pub_hash(h, 'whatev') }.not_to change { h }
    end
  end

  describe '.find_by_doi' do
    it 'returns one Publication that has this doi' do
      publication.pub_hash = pub_hash.merge(identifier: [{ type: 'doi', id: '10.1016/j.mcn.2012.03.008',
                                                           url: 'https://doi.org/10.1016/j.mcn.2012.03.008' }])
      publication.wos_uid = 'somevalue'
      publication.send(:sync_identifiers_in_pub_hash)
      publication.save!
      res = described_class.find_by_doi('10.1016/j.mcn.2012.03.008')
      expect(res.id).to eq(publication.id)
    end

    it "returns nil if the doi isn't found" do
      expect(described_class.find_by_doi('does not exist')).to be_nil
    end
  end

  describe '.for_uid' do
    it 'returns one Publication that has this uid' do
      publication.pub_hash = pub_hash.merge(identifier: [{ type: 'WosUID', id: 'ABC123' }])
      publication.send(:sync_identifiers_in_pub_hash)
      publication.save!
      expect(described_class.for_uid('ABC123').id).to eq(publication.id)
    end

    it 'returns nil if not found' do
      expect(described_class.for_uid('does not exist')).to be_nil
    end
  end

  describe '#authoritative_pmid_source?' do
    let(:pub) { described_class.new }

    it "returns true if the pub has a provenance of 'pubmed'" do
      pub.pub_hash = { provenance: 'pubmed' }
      expect(pub).to be_authoritative_pmid_source
      expect(pub).to be_pubmed_pub
      expect(pub).to be_harvested_pub
    end

    it "returns true if the pub has a provenance of 'sciencewire'" do
      pub.pub_hash = { provenance: 'sciencewire' }
      expect(pub).to be_authoritative_pmid_source
      expect(pub).to be_sciencewire_pub
      expect(pub).to be_harvested_pub
    end

    it "returns false if the pub does not have a provanance of 'pubmed' or 'sciencewire'" do
      pub.pub_hash = { provenance: 'cap' }
      expect(pub).not_to be_authoritative_pmid_source
      expect(pub).not_to be_harvested_pub
    end
  end

  describe '#rebuild_pub_hash' do
    it 'correctly rebuilds pub_hash from SciencewireSourceRecord'
    it 'correctly rebuilds pub_hash from PubmedSourceRecord'
    it 'correctly rebuilds pub_hash from WebofScienceRecord'
    it 'raises for non-harvested record (manual publication entry)' do
      pub = described_class.new(pub_hash: { provenance: 'cap' })
      expect { pub.rebuild_pub_hash }.to raise_error(RuntimeError)
    end

    it 'raises for unsupported provenance record' do
      pub = described_class.new(pub_hash: { provenance: 'other' })
      expect { pub.rebuild_pub_hash }.to raise_error(RuntimeError)
    end
  end

  describe 'unique constraints' do
    let(:publication) { create(:publication, wos_uid: '123') }
    let(:dup) { publication.dup }

    it 'blocks duplication of wos_uid' do
      expect { dup.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows novel wos_uid' do
      dup.wos_uid = '456'
      expect { dup.save! }.not_to raise_error
    end
  end

  describe '#wos_uid' do
    let(:wos_src_rec) { WebOfScienceSourceRecord.new(source_data: wos_record.to_xml) }
    let(:wos_record) { WebOfScience::Records.new(encoded_records:).first }
    let(:encoded_records) { File.read('spec/fixtures/wos_client/wos_encoded_records.html') }

    it 'is set automatically during save if web_of_science_source_record is present' do
      publication.web_of_science_source_record = wos_src_rec
      expect { publication.save! }.to change(publication, :wos_uid).from(nil).to(wos_src_rec.uid)
    end
  end

  describe '#with_active_author' do
    context 'when there is a publication with multiple active authors'
    before do
      create(:publication_with_contributions)
      pub = create(:publication_with_contributions)
      pub.authors.each do |author|
        author.active_in_cap = false
        author.save
      end
    end

    it 'returns single publication with active authors' do
      expect(described_class.with_active_author.count).to eq(1)
    end
  end
end
