# frozen_string_literal: true

describe PublicationsController, :vcr do
  before do
    headers = { 'HTTP_CAPKEY' => Settings.API_KEY, 'CONTENT_TYPE' => 'application/json' }
    request.headers.merge! headers
  end

  let(:publication) { FactoryBot.create :publication }
  let(:manual_publication) { FactoryBot.create :manual_publication }
  let(:wos_publication) { FactoryBot.create :wos_publication }

  let(:author) { FactoryBot.create :author }
  let(:valid_hash_for_post) do
    {
      type: 'book',
      title: 'some title',
      year: '1938',
      issn: '32242424',
      pages: '34-56',
      author: [{
        name: 'jackson joe'
      }],
      authorship: [{
        cap_profile_id: author.cap_profile_id,
        sul_author_id: author.id,
        status: 'denied',
        visibility: 'public',
        featured: true,
        additionalProperties: {}
      }]
    }
  end
  let(:valid_hash_for_post_with_nul_sul_author_and_uppercase_states) do
    {
      type: 'book',
      title: 'some title',
      year: '1938',
      issn: '32242424',
      pages: '34-56',
      author: [{
        name: 'jackson joe'
      }],
      authorship: [{
        cap_profile_id: author.cap_profile_id,
        sul_author_id: nil,
        status: 'DENIED',
        visibility: 'PUBLIC',
        featured: true,
        additionalProperties: {}
      }]
    }
  end
  let(:valid_json_for_post) { valid_hash_for_post.to_json }
  let(:doi_pub_id) { create(:doi_pub_id, identifier_value: '18819910019') }

  let(:invalid_json_for_post) do
    valid_hash_for_post.reject { |k, _| k == :authorship }.to_json
  end

  let(:json_with_new_author) do
    valid_hash_for_post.merge(
      author: [{ name: 'henry lowe' }],
      authorship: [{
        cap_profile_id: '3810',
        status: 'denied',
        visibility: 'public',
        featured: true
      }]
    ).to_json
  end

  let(:with_isbn_hash) do
    {
      abstract: '',
      abstract_restricted: '',
      allAuthors: 'author A, author B',
      author: [
        { firstname: 'John ', lastname: 'Doe', middlename: '', name: 'Doe  John ', role: 'author' },
        { firstname: 'Raj', lastname: 'Kathopalli', middlename: '', name: 'Kathopalli  Raj', role: 'author' }
      ],
      authorship: [
        { cap_profile_id: author.cap_profile_id, featured: true, status: 'approved', visibility: 'public' }
      ],
      booktitle: 'TEST Book I',
      edition: '2',
      identifier: [
        { type: 'isbn', id: '1177188188181' },
        doi_pub_id.identifier
      ],
      last_updated: '2013-08-10T21:03Z',
      provenance: 'CAP',
      publisher: 'Publisher',
      series: { number: '919', title: 'Series 1', volume: '1' },
      type: 'book',
      year: '2010'
    }
  end

  let(:with_isbn_changed_doi) do
    valid_hash_for_post.merge(
      identifier: [
        { type: 'isbn', id: '1177188188181' },
        { type: 'doi', id: '18819910019-updated', url: '18819910019-updated' },
        { type: 'SULPubId', id: '164', url: "#{Settings.SULPUB_ID.PUB_URI}/164" }
      ]
    )
  end

  let(:with_isbn_deleted_doi) do
    with_isbn_changed_doi.merge(
      identifier: [
        { type: 'isbn', id: '1177188188181' },
        { type: 'SULPubId', id: '164', url: "#{Settings.SULPUB_ID.PUB_URI}/164" }
      ]
    )
  end

  let(:json_with_pubmedid) do
    with_isbn_hash.merge(
      identifier: [
        { type: 'isbn', id: '1177188188181' },
        doi_pub_id.identifier,
        { type: 'pmid', id: '999999999' }
      ]
    ).to_json
  end

  let(:article_with_authorship_without_authors) do
    {
      allAuthors: '',
      author: [{}],
      authorship: [{
        cap_profile_id: author.cap_profile_id,
        featured: false,
        status: 'approved',
        visibility: 'public'
      }],
      journal: {},
      last_updated: '2015-11-23T15:15Z',
      provenance: 'CAP',
      publisher: '',
      type: 'article',
      title: 'Test Article2 11-23-2015',
      year: '2015'
    }.to_json
  end

  def post_valid_json
    post :create, body: valid_json_for_post, params: { format: 'json' }
    expect(response.status).to eq 201
  end

  # @param [Hash<Symbol => Object>] pub_hash
  # @param [Hash<String => Object>] submission from JSON.parse()
  def validate_authorship(pub_hash, submission)
    pub_hash = pub_hash.with_indifferent_access
    expect(pub_hash[:author]).to eq(submission['author'])
    expect(pub_hash[:authorship].length).to eq(submission['authorship'].length)
    matching_fields = %w[visibility status featured cap_profile_id]
    pub_hash[:authorship].each_with_index do |pub_authorship, index|
      sub_authorship = submission['authorship'][index]
      expect(sub_authorship).not_to be_empty
      expect(pub_authorship).not_to be_empty
      matching_fields.each do |field|
        pub_field = pub_authorship[field.to_sym]
        sub_field = sub_authorship[field]
        expect(sub_field).not_to be_nil
        expect(pub_field).not_to be_nil
        expect(pub_field).to eq(sub_field)
      end
    end
  end

  describe 'list publications' do
    let(:cap_id) { 'whatever' }

    it 'checks authorization' do
      expect(controller).to receive(:check_authorization)
      get :index, params: { capProfileId: cap_id, format: 'json' }
    end

    context 'with unknown capProfileId' do
      it 'returns a 404' do
        get :index, params: { capProfileId: cap_id, format: 'json' }
        expect(response.status).to eq 404
        expect(response.body).to include 'No such author'
      end
    end

    context 'with known capProfileId in json format' do
      let(:json_response) { JSON.parse(response.body) }

      before { allow(Author).to receive(:find_by).with(cap_profile_id: cap_id).and_return(author) }

      it 'returns a structured response' do
        get :index, params: { capProfileId: cap_id, format: 'json' }
        expect(response.status).to eq 200
        expect(json_response).to match a_hash_including(
          'metadata' => a_hash_including('format' => 'BibJSON', 'page' => 1, 'per_page' => 1000, 'records' => '0'),
          'records' => []
        )
      end
    end

    context 'with known capProfileId in csv format' do
      before { allow(Author).to receive(:find_by).with(cap_profile_id: cap_id).and_return(author) }

      it 'returns a structured response' do
        get :index, params: { capProfileId: cap_id, format: 'csv' }
        expect(response.status).to eq 200
        expect(response.body).to eq 'sul_pub_id,sciencewire_id,pubmed_id,doi,wos_id,title,journal,year,pages,issn,' \
                                    "status_for_this_author,created_at,updated_at,contributor_cap_profile_ids\n"
      end
    end
  end

  describe 'search for publications (GET sourcelookup)' do
    it 'checks authorization' do
      expect(controller).to receive(:check_authorization)
      allow(DoiSearch).to receive(:search).with('xyz').and_return([])
      get :sourcelookup, params: { doi: 'xyz', format: 'json' }
    end

    it 'returns bad request if no important params received' do
      get :sourcelookup, params: { format: 'json' }
      expect(response.status).to eq 400
      get :sourcelookup, params: { year: 2001, format: 'json' }
      expect(response.status).to eq 400
    end

    it 'returns not_acceptable if wrong format' do
      get :sourcelookup, params: { title: 'something cool', format: 'xml' }
      expect(response.status).to eq 406
    end

    it 'with doi calls DoiSearch' do # and ignores pmid & title
      expect(DoiSearch).to receive(:search).with('xyz').and_return([])
      expect(Pubmed::Fetcher).not_to receive(:search_all_sources_by_pmid)
      get :sourcelookup, params: { doi: 'xyz', pmid: 'abc', title: 'foo', format: 'json' }
    end

    it 'with pmid calls Pubmed::Fetcher' do
      expect(Pubmed::Fetcher).to receive(:search_all_sources_by_pmid).with('abc').and_return([])
      expect(DoiSearch).not_to receive(:search)
      get :sourcelookup, params: { pmid: 'abc', format: 'json' }
    end

    describe 'search by doi' do
      let(:doi_value) { '10.1016/j.mcn.2012.03.008' }
      let(:doi_identifier) do
        FactoryBot.create(:publication_identifier,
                          identifier_type: 'doi',
                          identifier_value: doi_value,
                          identifier_uri: "https://doi.org/#{doi_value}")
      end
      let(:result) do
        params = { format: 'json', doi: doi_value }
        get :sourcelookup, params: params
        expect(response.status).to eq(200)
        JSON.parse(response.body)
      end

      it 'calls WoS to search by doi' do
        expect(result['metadata']['records']).to eq('1')
        expect(result['records'].first['wos_uid']).to eq('WOS:000305547700008')
      end

      it 'does not query provider if there is an existing publication with the doi' do
        doi_identifier.publication.save
        expect(result['metadata']).to include('records' => '1')
        record = result['records'].first
        expect(record['title']).to match(/Protein kinase C alpha/i)
        expect(record['provenance']).to eq 'wos'
      end
    end

    describe 'search by pmid' do
      it 'returns one document if pubmed lookup is enabled' do
        allow(Settings.WOS).to receive(:enabled).and_return(false)
        allow(Settings.PUBMED).to receive(:lookup_enabled).and_return(true)
        params = { format: 'json', pmid: '24196758' }
        get :sourcelookup, params: params
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['metadata']).to include('records' => '1')
        record = result['records'].first
        expect(record).to include('mla_citation', 'chicago_citation')
        expect(record).to include('apa_citation' => /^Sittig, D. F./)
        expect(record['provenance']).to eq('pubmed')
      end

      it 'returns nothing if both pubmed and wos lookup is disabled' do
        allow(Settings.WOS).to receive(:enabled).and_return(false)
        allow(Settings.PUBMED).to receive(:lookup_enabled).and_return(false)
        params = { format: 'json', pmid: '24196758' }
        get :sourcelookup, params: params
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['metadata']).to include('records' => '0')
      end
    end

    describe 'search by title' do
      let(:queries) { instance_double(WebOfScience::Queries) }
      let(:test_title) { 'pathological' }
      let(:publication_with_test_title) { create :publication, title: test_title }
      let(:sourcelookup_by_title) do
        publication_with_test_title
        params = { format: 'json', title: test_title, maxrows: 2 }
        get :sourcelookup, params: params
        expect(response.status).to eq(200)
        JSON.parse(response.body)
      end

      it 'returns bibjson with expected sections' do
        result = sourcelookup_by_title
        expect(result).to include('metadata', 'records')
        expect(result['metadata']).not_to be_empty
        expect(result['records']).not_to be_empty
      end

      it 'with maxrows number of records' do
        params = { format: 'json', title: test_title, maxrows: 5 }
        get :sourcelookup, params: params
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['records'].length).to eq(5)
      end

      it 'does a title search' do
        allow(WebOfScience::Queries).to receive(:new).with('WOS').and_return(queries)
        expect(queries).to receive(:user_query)
          .with('TI="lung cancer treatment"')
          .and_return(instance_double(WebOfScience::Retriever, next_batch: Array.new(20) { {} }))
        params = { format: 'json', title: 'lung cancer treatment' }
        get :sourcelookup, params: params
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['metadata']['records']).to eq('20')
      end

      it 'returns results that match the requested title' do
        result = sourcelookup_by_title
        expect(result).to include('records')
        expect(result['records']).not_to be_empty
        records = result['records']
        matches = records.count { |r| r['title'] =~ /#{test_title}/i }
        expect(matches).to eq(records.count) # ALL records match
      end

      it 'returns results that match the requested year' do
        year = 2015.to_s
        allow(WebOfScience::Queries).to receive(:new).with('WOS').and_return(queries)
        expect(queries).to receive(:user_query)
          .with("TI=\"#{test_title}\" AND PY=2015")
          .and_return(instance_double(WebOfScience::Retriever, next_batch: ['year' => year]))
        params = { format: 'json', title: test_title, year: year }
        get :sourcelookup, params: params
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result).to include('records')
        expect(result['records']).not_to be_empty
        expect(result['records'].map { |r| r['year'] }).to all eq(year) # ALL records match
      end
    end

    context 'WOS disabled/enabled' do
      let(:json_response) { JSON.parse(response.body) }

      context 'WOS disabled' do
        before { allow(Settings.WOS).to receive(:enabled).and_return(false) }

        let(:ussr) { create :user_submitted_source_record, title: 'Men On Mars', year: '2001', source_data: '{}' }
        let!(:pub) do
          pub = build(:publication, title: ussr.title, year: ussr.year, user_submitted_source_records: [ussr])
          pub.pub_hash[:year] = ussr.year.to_s # values will overwrite from pub_hash
          pub.pub_hash[:title] = ussr.title
          pub.save!
          ussr.publication = pub # association does not automatically update ussr
          ussr.save!
          pub
        end

        it 'only searches local/manual pubs' do
          expect(WebOfScience).not_to receive(:queries)
          get :sourcelookup, params: { title: 'en On Ma', format: 'json' } # Partial title
          expect(json_response).to match a_hash_including(
            'metadata' => a_hash_including('format' => 'BibJSON', 'page' => 1, 'per_page' => 'all', 'records' => '1'),
            'records' => [a_hash_including('title' => pub.title, 'year' => pub.year)]
          )
        end
      end

      context 'WOS enabled' do
        let(:queries) { instance_double(WebOfScience::Queries) }
        let(:retriever) do
          instance_double(WebOfScience::Retriever, next_batch: WebOfScience::Records.new(records: '<xml/>'))
        end

        before do
          allow(Settings.WOS).to receive(:enabled).and_return(true)
          allow(WebOfScience::Queries).to receive(:new).with('WOS').and_return(queries)
        end

        it 'hits WOS' do
          expect(queries).to receive(:user_query).with('TI="xyz"').and_return(retriever)
          get :sourcelookup, params: { title: 'xyz', format: 'json' } # Partial title
        end

        it 'includes year if provided' do
          expect(queries).to receive(:user_query).with('TI="xyz" AND PY=2001').and_return(retriever)
          get :sourcelookup, params: { title: 'xyz', year: 2001, format: 'json' } # Partial title with year
        end

        it 'remove quotes from user query to avoid parsing errors' do
          expect(queries).to receive(:user_query).with('TI="xyz with quoted values in it"').and_return(retriever)
          get :sourcelookup, params: { title: 'xyz with "quoted values" in it', format: 'json' } # title with quotes
        end
      end
    end
  end

  describe 'create manual publication' do
    let(:result) { JSON.parse(response.body) }
    let(:last_pub) { Publication.last }

    context 'when valid post' do
      let(:submission) { JSON.parse(valid_json_for_post) }

      it 'responds with 201' do
        post_valid_json
      end

      it 'returns bibjson from the pub_hash for the new publication' do
        post_valid_json
        expect(response.body).to eq(last_pub.pub_hash.to_json)
      end

      it 'creates a new contributions record in the db' do
        post_valid_json
        expect(Contribution.where(publication_id: last_pub.id, author_id: author.id).first.status).to eq('denied')
      end

      it 'increases number of contribution records by one' do
        expect { post_valid_json }.to change(Contribution, :count).by(1)
      end

      it 'increases number of publication records by one' do
        expect { post_valid_json }.to change(Publication, :count).by(1)
      end

      it 'increases number of user submitted source records by one' do
        expect { post_valid_json }.to change(UserSubmittedSourceRecord, :count).by(1)
      end

      it 'creates an appropriate publication record from the posted bibjson' do
        post_valid_json
        expect(last_pub.title).to eq(submission['title'])
        expect(last_pub.year).to eq(submission['year'])
        expect(last_pub.pages).to eq(submission['pages'])
        expect(last_pub.issn).to eq(submission['issn'])
      end

      it 'creates a matching pub_hash in the publication record from the posted bibjson' do
        post_valid_json
        validate_authorship(last_pub.pub_hash, submission)
      end

      it 'handles missing author using authorship from the posted bibjson' do
        post :create, body: article_with_authorship_without_authors, params: { format: 'json' }
        expect(response.status).to eq(201)
        validate_authorship(last_pub.pub_hash, JSON.parse(article_with_authorship_without_authors))
      end

      it 'creates a pub with matching authorship info in hash and contributions table' do
        post_valid_json
        authorship = JSON.parse(valid_json_for_post)['authorship'][0]
        contrib = Contribution.find_by(publication_id: last_pub.id, author_id: author.id)
        # TODO: evaluate whether authorship array should result in one or more contributions?
        expect(contrib.visibility).to eq(authorship['visibility'])
        expect(contrib.status).to eq(authorship['status'])
        expect(contrib.featured).to eq(authorship['featured'])
        expect(contrib.cap_profile_id).to eq(authorship['cap_profile_id'])
      end

      it 'does not duplicate SULPubIds' do
        json_with_sul_pub_id = { type: 'book', identifier: [{ type: 'SULPubId', id: 'n', url: 'm' }],
                                 authorship: [{ sul_author_id: author.id, status: 'denied', visibility: 'public', featured: true }] }.to_json
        post :create, body: json_with_sul_pub_id, params: { format: 'json' }
        expect(response.status).to eq(201)
        expect(result['identifier'].count { |x| x['type'] == 'SULPubId' }).to eq(1)
        expect(result['identifier'][0]['id']).not_to eq('n')
      end

      it 'creates a pub with a null sul_author_id' do
        post :create, body: valid_hash_for_post_with_nul_sul_author_and_uppercase_states.to_json, params: { format: 'json' }
        expect(response.status).to eq(201)
        expect(response.body).to eq(last_pub.pub_hash.to_json)
      end

      it 'creates a pub with isbn' do
        post :create, body: with_isbn_hash.to_json, params: { format: 'json' }
        expect(response.status).to eq(201)
        # TODO: use the submission data to validate some of the identifier fields
        # submission = JSON.parse(json_with_isbn)
        expect(result['identifier'].size).to eq(3)
        expect(result['identifier']).to include(
          a_hash_including('id' => '1177188188181', 'type' => 'isbn'),
          a_hash_including('type' => 'doi', 'url' => 'https://doi.org/18819910019'),
          a_hash_including('type' => 'SULPubId', 'url' => "#{Settings.SULPUB_ID.PUB_URI}/#{last_pub.id}",
                           'id' => last_pub.id.to_s)
        )
        expect(last_pub.publication_identifiers.size).to eq(2)
        expect(last_pub.publication_identifiers.map(&:identifier_type)).to include('doi', 'isbn')
        expect(response.body).to eq(last_pub.pub_hash.to_json)
      end

      it 'creates a pub with pmid' do
        post :create, body: json_with_pubmedid, params: { format: 'json' }
        expect(response.status).to eq(201)
        expect(result['identifier']).to include('id' => '999999999', 'type' => 'pmid')
        expect(last_pub.publication_identifiers.map(&:identifier_type)).to include('pmid')
        expect(response.body).to eq(last_pub.pub_hash.to_json)
      end
    end

    context 'when valid post' do
      it 'returns 303 (see other) for duplicate pub' do
        post :create, body: valid_json_for_post, params: { format: 'json' }
        expect(response.status).to eq(201)
        post :create, body: valid_json_for_post, params: { format: 'json' }
        expect(response.status).to eq(303)
      end

      it 'returns 406 - Not Acceptable for bibjson without an authorship entry' do
        post :create, body: invalid_json_for_post, params: { format: 'json' }
        expect(response.status).to eq(406)
      end

      it 'creates an Author when a new cap_profile_id is passed in' do
        skip 'Administrative Systems firewall only allows IP-based requests'
        post :create, body: json_with_new_author, params: { format: 'json' }
        expect(response.status).to eq(201)
        expect(Author.find_by(cap_profile_id: '3810').cap_last_name).to eq('Lowe')
      end
    end
  end

  describe 'update manual publication' do
    let(:result) { JSON.parse(response.body) }

    context 'successfully' do
      it 'does not duplicate SULPubIDs' do
        json_with_sul_pub_id = {
          type: 'book',
          identifier: [{
            type: 'SULPubId',
            id: 'n',
            url: 'm'
          }],
          authorship: [{
            sul_author_id: author.id,
            status: 'denied',
            visibility: 'public',
            featured: true
          }]
        }.to_json
        put :update, params: { id: manual_publication.id, format: 'json' }, body: json_with_sul_pub_id
        expect(result['identifier'].count { |x| x['type'] == 'SULPubId' }).to eq(1)
        expect(result['identifier'][0]['id']).not_to eq('n')
        expect(response.status).to eq(202)
      end

      it 'updates existing manual pub' do
        id = manual_publication.id
        expect(manual_publication).not_to be_harvested_pub
        expect(manual_publication.pub_hash[:identifier].size).to eq(3) # database has three identifiers
        expect(manual_publication.pub_hash[:identifier]).to include(
          a_hash_including(type: 'isbn', id: '1177188188181'),
          a_hash_including(type: 'doi', id: '18819910019', url: 'http://doi:18819910019'),
          a_hash_including(type: 'SULPubId', url: "#{Settings.SULPUB_ID.PUB_URI}/#{id}", id: id.to_s)
        )
        put :update, params: { id: id, format: 'json' }, body: with_isbn_changed_doi.to_json
        manual_publication.reload
        expect(manual_publication.pub_hash[:identifier].size).to eq(3) # database still has three identifiers
        expect(result['identifier'].size).to eq(3) # response also has three identifiers
        expect(manual_publication.pub_hash[:identifier]).to include(
          a_hash_including(type: 'isbn', id: '1177188188181'),
          a_hash_including(type: 'doi', id: '18819910019-updated', url: '18819910019-updated'), # doi is changed in the database
          a_hash_including(type: 'SULPubId', url: "#{Settings.SULPUB_ID.PUB_URI}/#{id}", id: id.to_s)
        )
        expect(response.status).to eq(202) # updated
      end

      it 'deletes an identifier from the db if it is not in the incoming json for a manual publication' do
        id = manual_publication.id
        expect(manual_publication).not_to be_harvested_pub
        expect(manual_publication.pub_hash[:identifier].size).to eq(3) # database has three identifiers
        expect(manual_publication.pub_hash[:identifier]).to include(
          a_hash_including(type: 'isbn', id: '1177188188181'),
          a_hash_including(type: 'doi', id: '18819910019', url: 'http://doi:18819910019'),
          a_hash_including(type: 'SULPubId', url: "#{Settings.SULPUB_ID.PUB_URI}/#{id}", id: id.to_s)
        )
        put :update, params: { id: id, format: 'json' }, body: with_isbn_deleted_doi.to_json
        manual_publication.reload
        expect(manual_publication.pub_hash[:identifier].size).to eq(2) # database has only two identifiers now
        expect(result['identifier'].size).to eq(2) # response also only has two identifiers
        expect(manual_publication.pub_hash[:identifier]).to include( # doi is now gone from the database
          a_hash_including(type: 'isbn', id: '1177188188181'),
          a_hash_including(type: 'SULPubId', url: "#{Settings.SULPUB_ID.PUB_URI}/#{id}", id: id.to_s)
        )
        expect(response.status).to eq(202) # updated
      end

      it 'refuses to update a wos pub' do
        id = wos_publication.id
        expect(wos_publication).to be_harvested_pub
        put :update, params: { id: id, format: 'json' }, body: with_isbn_changed_doi.to_json
        expect(response.status).to eq(403) # forbidden
      end
    end

    context 'fails' do
      context 'pub not found' do
        it 'returns 404' do
          put :update, params: { id: '8888888', format: 'json' }, body: with_isbn_hash.to_json
          expect(response.status).to eq(404)
        end
      end

      context 'when existing pub already has' do
        let(:id) { '1' }

        before { allow(Publication).to receive(:find_by).with(id: id).and_return(publication) }

        it 'been deleted' do
          allow(publication).to receive(:deleted?).and_return(true)
          put :update, params: { id: id, format: 'json' }, body: with_isbn_hash.to_json
          expect(response.status).to eq(410)
        end

        it 'sciencewire_id' do
          allow(publication).to receive(:sciencewire_id).and_return(2)
          put :update, params: { id: id, format: 'json' }, body: with_isbn_hash.to_json
          expect(response.status).to eq(403)
        end

        it 'pmid' do
          allow(publication).to receive(:pmid).and_return(3)
          put :update, params: { id: id, format: 'json' }, body: with_isbn_hash.to_json
          expect(response.status).to eq(403)
        end

        it 'wos_uid' do
          allow(publication).to receive(:wos_uid).and_return(4)
          put :update, params: { id: id, format: 'json' }, body: with_isbn_hash.to_json
          expect(response.status).to eq(403)
        end
      end
    end
  end

  describe 'show publication' do
    it 'returns 200 for valid call' do
      get :show, params: { id: publication.id, format: 'json' }
      expect(response.status).to eq(200)
    end

    it 'returns a publication bibjson doc by id' do
      get :show, params: { id: publication.id, format: 'json' }
      expect(response.body).to eq(publication.pub_hash.to_json)
    end

    it 'returns a pub with valid bibjson for sw harvested records' do
      allow(Publication)
        .to receive(:find_by)
        .with(id: '123')
        .and_return(instance_double(Publication, pub_hash: { 'provenance' => 'sciencewire', 'type' => 'article' },
                                                 deleted?: false))
      get :show, params: { id: '123', format: 'json' }
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to include('provenance' => 'sciencewire', 'type' => 'article')
    end

    it 'returns only those pubs changed since specified date'
    it 'returns only those pubs with contributions for the given author'
    it 'returns only pubs with a cap active profile'

    context "when pub id doesn't exist" do
      it 'returns not found code' do
        get :show, params: { id: '88888888', format: 'json' }
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'list publications' do
    let(:result) { JSON.parse(response.body) }

    context 'with no params specified, returns successfully with no results' do
      it 'returns first page' do
        get :index, params: { format: 'json' }
        expect(result['records']).to eq []
        expect(response.status).to eq(200)
      end
    end

    it "raises an error if a capkey isn't provided" do
      request.headers['HTTP_CAPKEY'] = nil # no key provided
      get :index, params: { page: 1, per: 7, format: 'json' }
      expect(response.status).to eq(401)
    end

    context 'when there are many records' do
      before { create_list(:contribution, 15, visibility: 'public', status: 'approved') }

      it 'returns one page with specified number of records' do
        get :index, params: { page: 1, per: 7, format: 'json' }
        expect(response.headers['Content-Type']).to be =~ %r{application/json}
        expect(result['metadata']).to include('records' => '7', 'page' => 1)
        expect(result['records'][2]['author']).to eq ['name' => 'Jackson, Joe']
        expect(response.status).to eq(200)
      end

      it 'filters by active authors' do
        get :index, params: { page: 1, per: 7, capActive: true, format: 'json' }
        expect(result['metadata']).to include('records' => '7', 'page' => 1)
        expect(response.status).to eq(200)
      end

      it 'paginates by active authors' do
        get :index, params: { page: 2, per: 1, capActive: true, format: 'json' }
        expect(result['metadata']).to include('records' => '1', 'page' => 2)
        expect(response.status).to eq(200)
      end
    end
  end
end
