describe SulBib::API, :vcr do
  let(:publication) { FactoryBot.create :publication }
  let(:author) { FactoryBot.create :author }
  let(:headers) { { 'HTTP_CAPKEY' => Settings.API_KEY, 'CONTENT_TYPE' => 'application/json' } }
  let(:valid_hash_for_post) do
    {
      type: 'book',
      title: 'some title',
      year: 1938,
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
        featured: true
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
      etal: true,
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
        { type: 'SULPubId', id: '164', url: Settings.SULPUB_ID.PUB_URI + '/164' }
      ]
    )
  end

  let(:with_isbn_deleted_doi) do
    with_isbn_changed_doi.merge(
      identifier: [
        { type: 'isbn', id: '1177188188181' },
        { type: 'SULPubId', id: '164', url: Settings.SULPUB_ID.PUB_URI + '/164' }
      ]
    )
  end

  let(:json_with_pubmedid) do
    with_isbn_hash.merge(
      identifier: [
        { type: 'isbn', id: '1177188188181' },
        doi_pub_id.identifier,
        { type: 'pmid', id: '999999999' },
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
      etal: false,
      journal: {},
      last_updated: '2015-11-23T15:15Z',
      provenance: 'CAP',
      publisher: '',
      type: 'article',
      title: 'Test Article2 11-23-2015',
      year: '2015'
    }.to_json
  end

  # ---------------------------------------------------------------------
  # POST

  def post_valid_json
    post '/publications', valid_json_for_post, headers
    expect(response.status).to eq(201)
  end

  # @param [Hash<Symbol => Object>] pub_hash
  # @param [Hash<String => Object>] submission from JSON.parse()
  def validate_authorship(pub_hash, submission)
    pub_hash = pub_hash.with_indifferent_access
    expect(pub_hash[:author]).to eq(submission['author'])
    expect(pub_hash[:authorship].length).to eq(submission['authorship'].length)
    matching_fields = %w(visibility status featured cap_profile_id)
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

  describe 'POST /publications' do
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
        expect(last_pub.pages).to eq(submission['pages'].sub('-', '–')) # em-dash
        expect(last_pub.issn).to eq(submission['issn'])
      end

      it 'creates a matching pub_hash in the publication record from the posted bibjson' do
        post_valid_json
        validate_authorship(last_pub.pub_hash, submission)
      end

      it 'handles missing author using authorship from the posted bibjson' do
        post '/publications', article_with_authorship_without_authors, headers
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
        json_with_sul_pub_id = { type: 'book', identifier: [{ type: 'SULPubId', id: 'n', url: 'm' }], authorship: [{ sul_author_id: author.id, status: 'denied', visibility: 'public', featured: true }] }.to_json
        post '/publications', json_with_sul_pub_id, headers
        expect(response.status).to eq(201)
        expect(result['identifier'].count { |x| x['type'] == 'SULPubId' }).to eq(1)
        expect(result['identifier'][0]['id']).not_to eq('n')
      end

      it 'creates a pub with with isbn' do
        post '/publications', with_isbn_hash.to_json, headers
        expect(response.status).to eq(201)
        # TODO: use the submission data to validate some of the identifier fields
        # submission = JSON.parse(json_with_isbn)
        expect(result['identifier'].size).to eq(3)
        expect(result['identifier']).to include(
          a_hash_including('id' => '1177188188181', 'type' => 'isbn'),
          a_hash_including('type' => 'doi', 'url' => 'https://doi.org/18819910019'),
          a_hash_including('type' => 'SULPubId', 'url' => "#{Settings.SULPUB_ID.PUB_URI}/#{last_pub.id}", 'id' => last_pub.id.to_s)
        )
        expect(last_pub.publication_identifiers.size).to eq(2)
        expect(last_pub.publication_identifiers.map(&:identifier_type)).to include('doi', 'isbn')
        expect(response.body).to eq(last_pub.pub_hash.to_json)
      end

      it 'creates a pub with with pmid' do
        post '/publications', json_with_pubmedid, headers
        expect(response.status).to eq(201)
        expect(result['identifier']).to include('id' => '999999999', 'type' => 'pmid')
        expect(last_pub.publication_identifiers.map(&:identifier_type)).to include('pmid')
        expect(response.body).to eq(last_pub.pub_hash.to_json)
      end
    end # end of the context

    context 'when valid post' do
      it 'returns 302 for duplicate pub' do
        post '/publications', valid_json_for_post, headers
        expect(response.status).to eq(201)
        post '/publications', valid_json_for_post, headers
        expect(response.status).to eq(302)
      end

      it 'returns 406 - Not Acceptable for bibjson without an authorship entry' do
        post '/publications', invalid_json_for_post, headers
        expect(response.status).to eq(406)
      end

      it 'creates an Author when a new cap_profile_id is passed in' do
        skip 'Administrative Systems firewall only allows IP-based requests'
        post '/publications', json_with_new_author, headers
        expect(response.status).to eq(201)
        expect(Author.find_by(cap_profile_id: '3810').cap_last_name).to eq('Lowe')
      end
    end
  end # end of the describe

  # ---------------------------------------------------------------------
  # PUT

  describe 'PUT /publications/:id' do
    let(:result) { JSON.parse(response.body) }

    context 'successfully' do
      after { expect(response.status).to eq(200) }

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
        put "/publications/#{publication.id}", json_with_sul_pub_id, headers
        expect(result['identifier'].count { |x| x['type'] == 'SULPubId' }).to eq(1)
        expect(result['identifier'][0]['id']).not_to eq('n')
      end

      it 'updates existing pub' do
        post '/publications', with_isbn_hash.to_json, headers
        id = Publication.last.id
        put "/publications/#{id}", with_isbn_changed_doi.to_json, headers
        expect(result['identifier'].size).to eq(3)
        expect(result['identifier']).to include(
          a_hash_including('type' => 'isbn', 'id' => '1177188188181'),
          a_hash_including('type' => 'doi', 'url' => '18819910019-updated'),
          a_hash_including('type' => 'SULPubId', 'url' => "#{Settings.SULPUB_ID.PUB_URI}/#{id}", 'id' => id.to_s)
        )
      end

      it 'deletes an identifier from the db if it is not in the incoming json' do
        post '/publications', with_isbn_hash.to_json, headers
        id = Publication.last.id
        put "/publications/#{id}", with_isbn_deleted_doi.to_json, headers
        expect(result['identifier'].size).to eq(2)
        expect(result['identifier']).to include(
          a_hash_including('type' => 'isbn', 'id' => '1177188188181'),
          a_hash_including('type' => 'SULPubId', 'url' => "#{Settings.SULPUB_ID.PUB_URI}/#{id}", 'id' => id.to_s)
        )
      end
    end

    context 'fails' do
      context 'pub not found' do
        it 'returns 404' do
          put '/publications/88888888888', with_isbn_hash.to_json, headers
          expect(response.status).to eq(404)
        end
      end

      context 'when existing pub already has' do
        let(:id) { '1' }
        before { allow(Publication).to receive(:find).with(id).and_return(publication) }

        it 'been deleted' do
          allow(publication).to receive(:deleted?).and_return(true)
          put "/publications/#{id}", with_isbn_hash.to_json, headers
          expect(response.status).to eq(410)
        end
        it 'sciencewire_id' do
          allow(publication).to receive(:sciencewire_id).and_return(2)
          put "/publications/#{id}", with_isbn_hash.to_json, headers
          expect(response.status).to eq(403)
        end
        it 'pmid' do
          allow(publication).to receive(:pmid).and_return(3)
          put "/publications/#{id}", with_isbn_hash.to_json, headers
          expect(response.status).to eq(403)
        end
        it 'wos_uid' do
          allow(publication).to receive(:wos_uid).and_return(4)
          put "/publications/#{id}", with_isbn_hash.to_json, headers
          expect(response.status).to eq(403)
        end
      end
    end
  end

  # ---------------------------------------------------------------------
  # GET

  describe 'GET /publications/:id' do
    it 'returns 200 for valid call' do
      get "/publications/#{publication.id}", { format: 'json' }, headers
      expect(response.status).to eq(200)
    end
    it 'returns a publication bibjson doc by id' do
      get "/publications/#{publication.id}", { format: 'json' }, headers
      expect(response.body).to eq(publication.pub_hash.to_json)
    end

    it 'returns a pub with valid bibjson for sw harvested records' do
      author.contributions.destroy_all # wipe the slate clean
      ScienceWireHarvester.new.harvest_pubs_for_author_ids([author.id])
      new_pub = Publication.last
      get "/publications/#{new_pub.id}", { format: 'json' }, headers
      expect(response.status).to eq(200)
      expect(response.body).to eq(new_pub.pub_hash.to_json)
      expect(JSON.parse(response.body)).to include('provenance' => 'sciencewire', 'type' => 'article')
    end

    it 'returns only those pubs changed since specified date'
    it 'returns only those pubs with contributions for the given author'
    it 'returns only pubs with a cap active profile'

    context "when pub id doesn't exist" do
      it 'returns not found code' do
        get '/publications/88888888888', { format: 'json' }, headers
        expect(response.status).to eq(404)
      end
    end
  end # end of the describe

  describe 'GET /publications' do
    let(:result) { JSON.parse(response.body) }

    context 'with no params specified' do
      it 'returns first page' do
        get '/publications/', { format: 'json' }, headers
        expect(result['records']).to be
      end
    end

    it "raises an error if a capkey isn't provided" do
      get '/publications?page=1&per=7', format: 'json' # no headers
      expect(response.status).to eq(401)
    end

    context 'when there are many records' do
      before { create_list(:contribution, 15, visibility: 'public', status: 'approved') }
      after { expect(response.status).to eq(200) }

      it 'returns one page with specified number of records' do
        get '/publications?page=1&per=7', { format: 'json' }, headers
        expect(response.headers['Content-Type']).to be =~ %r{application/json}
        expect(result['metadata']).to include('records' => '7', 'page' => 1)
        expect(result['records'][2]['author']).to be
      end

      it 'filters by active authors' do
        get '/publications?page=1&per=1&capActive=true', { format: 'json' }, headers
        expect(result['metadata']).to include('records' => '1', 'page' => 1)
      end

      it 'paginates by active authors' do
        get '/publications?page=2&per=1&capActive=true', { format: 'json' }, headers
        expect(result['metadata']).to include('records' => '1', 'page' => 2)
      end
    end # end of context
  end # end of the describe
end
