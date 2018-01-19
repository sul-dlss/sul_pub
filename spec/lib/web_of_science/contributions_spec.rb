describe WebOfScience::Contributions do
  subject(:wos_contributions) { test_class.new }

  let(:test_class) { Class.new { include WebOfScience::Contributions } } # or described_class

  let(:author) do
    # public data from
    # - https://stanfordwho.stanford.edu
    # - https://med.stanford.edu/profiles/russ-altman
    FactoryBot.create(:author,
                      preferred_first_name: 'Russ',
                      preferred_last_name: 'Altman',
                      preferred_middle_name: 'Biagio',
                      email: 'Russ.Altman@stanford.edu',
                      cap_import_enabled: true)
  end

  let(:wos_uids) { %w(WOS:A1976BW18000001 WOS:A1972N549400003) }
  let(:wos_A1972N549400003) { File.read('spec/fixtures/wos_client/wos_record_A1972N549400003.xml') }
  let(:wos_A1976BW18000001) { File.read('spec/fixtures/wos_client/wos_record_A1976BW18000001.xml') }
  let(:rec_A1972N549400003) { WebOfScience::Record.new(record: wos_A1972N549400003) }
  let(:rec_A1976BW18000001) { WebOfScience::Record.new(record: wos_A1976BW18000001) }

  let(:contrib_A1972N549400003) do
    contrib = pub_A1972N549400003.contributions.find_or_initialize_by(
      author_id: author.id, cap_profile_id: author.cap_profile_id,
      featured: false, status: 'new', visibility: 'private'
    )
    contrib.save
    contrib
  end

  let(:pub_A1972N549400003) do
    pub = Publication.new(active: true, pub_hash: rec_A1972N549400003.pub_hash, wos_uid: rec_A1972N549400003.uid)
    pub.sync_publication_hash_and_db # callbacks create PublicationIdentifiers etc.
    pub.save!
    pub
  end

  let(:check_contributions) { wos_contributions.author_contributions(author, wos_uids) }

  before do
    # create one of the publications, without any contributions
    expect(pub_A1972N549400003.persisted?).to be true
  end

  it 'returns the WOS-UID for existing publications' do
    expect(check_contributions).to eq ['WOS:A1972N549400003']
  end

  it 'creates a new contribution for an existing publication, without a contribution' do
    # Use a publication WITHOUT a contribution for WOS:A1972N549400003
    expect { check_contributions }.to change { pub_A1972N549400003.contributions.count }.by(1)
  end

  it 'makes no changes for existing publications with a contribution' do
    expect(contrib_A1972N549400003.persisted?).to be true
    expect { check_contributions }.not_to change { pub_A1972N549400003.contributions.count }
  end

  it 'makes no changes for any WOS-UID without an existing publication/contribution' do
    expect(Publication.find_by(wos_uid: 'WOS:A1976BW18000001')).to be_nil
    expect { check_contributions }.not_to change { Publication.find_by(wos_uid: 'WOS:A1976BW18000001') }
  end
end
