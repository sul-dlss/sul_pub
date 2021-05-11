describe AuthorshipsController, :vcr do
  before do
    headers = { 'HTTP_CAPKEY' => Settings.API_KEY, 'CONTENT_TYPE' => 'application/json' }
    request.headers.merge! headers
  end

  let(:publication) { create :publication }
  let(:author) { create :author }
  let(:sul_author_hash) { { sul_author_id: author.id } }
  let(:author_hash) { { cap_profile_id: author.cap_profile_id } }

  let(:contribution_count) { 2 }
  # let is lazy-evaluated: it is evaluated the first time it's method is invoked.
  # Use let! to force the method's invocation before each example.
  let!(:publication_with_contributions) do
    pub = create :publication_with_contributions, contributions_count: contribution_count
    # FactoryBot knows nothing about the Publication.pub_hash sync issue, so
    # it must be forced to update that data with the contributions.
    pub.pubhash_needs_update!
    pub.save # to update the pub.pub_hash
    pub
  end
  let(:base_data) do
    {
      featured: false,
      status: 'denied',
      visibility: 'private'
    }
  end
  let(:valid_data_for_post) { base_data.merge(sul_pub_id: publication.id) }
  let(:existing_contrib) { publication_with_contributions.contributions.first }
  let(:existing_contrib_ids) do
    {
      # author_hash is NOT merged here, because this data is concerned with an existing contribution.
      sul_author_id: existing_contrib.author.id,
      sul_pub_id: existing_contrib.publication.id
    }
  end
  let(:update_authorship_for_pub_with_contributions) { existing_contrib_ids.merge(base_data) }

  shared_examples 'it issues an error without author params' do
    let(:request_data) { valid_data_for_post }
    it 'returns 400 with an error message' do
      http_request
      expect(response.status).to eq 400
      result = JSON.parse(response.body)
      expect(result['error']).to include('sul_author_id', 'cap_profile_id')
    end
  end

  shared_examples 'it issues errors when sul_author_id does not exist' do
    let(:sul_author_id) { '999999' }
    let(:request_data) { valid_data_for_post.merge(sul_author_id: sul_author_id) }

    it 'returns 404 when it fails to find a sul_author_id' do
      http_request
      expect(response.status).to eq 404
      result = JSON.parse(response.body)
      expect(result['error']).to include('sul_author_id', sul_author_id)
    end
  end

  shared_examples 'it issues errors for cap_profile_id' do
    let(:cap_profile_id) { '999999' }
    let(:request_data) { valid_data_for_post.merge(cap_profile_id: cap_profile_id) }

    it 'returns 404 when it fails to find a cap_profile_id' do
      http_request
      expect(response.status).to eq 404
      result = JSON.parse(response.body)
      expect(result['error']).to include('cap_profile_id', cap_profile_id)
    end
    it 'returns 404 when it cannot retrieve a cap_profile_id' do
      expect(Author).to receive(:fetch_from_cap_and_create).with(cap_profile_id)
      http_request
      expect(response.status).to eq 404
    end
  end

  shared_examples 'it handles invalid authorship attributes' do
    let(:request_data) { update_authorship_for_pub_with_contributions.merge(visibility: 'invalid value') }
    it 'returns 406' do
      http_request
      result = JSON.parse(response.body)
      expect(result['error']).to include('You have not supplied a valid authorship record')
      expect(response.status).to eq 406
    end
  end

  describe 'Create new authorship records via a POST' do
    let(:new_pub) { Publication.last }
    let(:http_request) { post :create, body: request_data.to_json, params: { format: 'json' } }

    context 'errors' do
      it_behaves_like 'it issues an error without author params'
      it_behaves_like 'it issues errors when sul_author_id does not exist'
      it_behaves_like 'it issues errors for cap_profile_id'
      it_behaves_like 'it handles invalid authorship attributes'
    end

    context 'with no contributions' do
      let(:request_data) { valid_data_for_post.merge(sul_author_hash) }
      it 'successfully creates one new contribution' do
        expect { http_request }.to change(Contribution, :count).by(1)
        expect(response.status).to eq 201
      end
    end

    context 'with allcaps or mixed case strings' do
      let(:request_data) { sul_author_hash.merge(sul_pub_id: publication_with_contributions.id, visibility: 'PRIVATE', status: 'New', featured: true) }
      it 'downcases appropriately' do
        expect { http_request }.not_to change { existing_contrib }
        contrib = publication_with_contributions.contributions.reload.last
        expect(contrib.status).to eq 'new'
        expect(contrib.visibility).to eq 'private'
        expect(response.status).to eq 201
      end
    end

    context 'with prior contributions' do
      let(:request_data) { base_data.merge(sul_pub_id: publication_with_contributions.id).merge(author_hash) }

      it "successfully increases the publication's contribution records by one" do
        expect { http_request }.to change(publication_with_contributions.contributions, :count).by(1)
        expect(response.status).to eq 201
        expect(publication_with_contributions.contributions.count).to eq(contribution_count + 1)
      end
      it 'creates one contribution record with matching attributes' do
        http_request
        query = Contribution.where(
          publication_id: publication_with_contributions.id,
          author_id: author.id
        )
        expect(query.count).to eq 1
        contribution = query.first
        expect(contribution.featured).to be false
        expect(contribution.status).to eq('denied')
        expect(contribution.visibility).to eq('private')
        expect(response.status).to eq 201
      end
      it 'adds the authorship entry to the pub_hash for the publication' do
        http_request
        authorship = publication_with_contributions.reload.pub_hash[:authorship]
        expect(authorship.any? { |a| a[:sul_author_id] == author.id }).to be true
      end
      it 'adds one authorship entry to response pub_hash' do
        # This specifically checks response data, whereas the prior spec checks data model.
        # Expect a change in the number of contributions
        http_request
        result = JSON.parse(response.body)
        result_authorship = result['authorship']
        expect(result_authorship.length).to eq(contribution_count + 1)
        authorship_matches = result_authorship.select do |a|
          a['sul_author_id'] == author.id
        end
        expect(authorship_matches.length).to eq 1
        expect(authorship_matches.first).to include('status' => 'denied', 'featured' => false, 'visibility' => 'private')
      end
    end

    context 'for a new PubMed publication' do
      let(:request_data) { base_data.merge(pmid: '23684686').merge(author_hash) }
      before { http_request }

      it 'adds new publication' do
        result = JSON.parse(response.body)
        expect(result['pmid']).to eq(request_data[:pmid])
        expect(result['authorship'].length).to eq 1
        contribution = Contribution.find_by(
          publication_id: new_pub.id,
          author_id: author.id
        )
        expect(contribution.featured).to eq(request_data[:featured])
        expect(contribution.status).to eq(request_data[:status])
        expect(contribution.visibility).to eq(request_data[:visibility])
        expect(response.body).to eq(new_pub.pub_hash.to_json)
      end

      it 'adds proper identifiers section' do
        result = JSON.parse(response.body)
        expect(result['identifier']).to include(
          a_hash_including('type' => 'PMID', 'id' => request_data[:pmid], 'url' => "https://www.ncbi.nlm.nih.gov/pubmed/#{request_data[:pmid]}"),
          a_hash_including('type' => 'SULPubId', 'id' => new_pub.id.to_s, 'url' => "#{Settings.SULPUB_ID.PUB_URI}/#{new_pub.id}")
        )
        expect(response.body).to eq(new_pub.pub_hash.to_json)
      end
    end

    context 'for a new WoS publication' do
      # set Savon in and out of mock mode
      require 'savon/mock/spec_helper'
      include Savon::SpecHelper

      after { savon.unmock! }

      let(:request_data) { base_data.merge(wos_uid: wos_record_uid).merge(author_hash) }

      let(:wos_record_uid) { 'WOS:A1972N549400003' }
      let(:wos_retrieve_by_id_response) { File.read('spec/fixtures/wos_client/wos_record_A1972N549400003_response.xml') }
      let(:wos_auth_response) { File.read('spec/fixtures/wos_client/authenticate.xml') }

      before do
        savon.mock!
        # Mock a WOS-API and Links-API interaction
        wos_client = WebOfScience::Client.new('secret')
        allow(WebOfScience).to receive(:client).and_return(wos_client)
        links_client = Clarivate::LinksClient.new
        wos_record_links = { wos_record_uid => { 'doi' => '10.5860/crl_33_05_413' } }
        allow(links_client).to receive(:links).with([wos_record_uid]).and_return(wos_record_links)
        allow(WebOfScience).to receive(:links_client).and_return(links_client)
        savon.expects(:authenticate).returns(wos_auth_response)
        savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_response)
        # Issue an API call and check the response status
        http_request
      end

      it 'adds new WoS publication' do
        result = JSON.parse(response.body)
        expect(result['wos_uid']).to eq(request_data[:wos_uid])
        expect(result['authorship'].length).to eq 1
        expect(result['authorship'][0]['sul_author_id']).to eq(author.id)
        contribution = Contribution.find_by(
          publication_id: new_pub.id,
          author_id: author.id
        )
        expect(contribution.featured).to eq(request_data[:featured])
        expect(contribution.status).to eq(request_data[:status])
        expect(contribution.visibility).to eq(request_data[:visibility])
        expect(response.body).to eq(new_pub.pub_hash.to_json)
      end

      it 'adds new WoS publication with proper identifiers section' do
        result = JSON.parse(response.body)
        expect(result['identifier']).to include(
          a_hash_including('type' => 'WosUID', 'id' => request_data[:wos_uid]),
          a_hash_including('type' => 'SULPubId', 'id' => new_pub.id.to_s, 'url' => "#{Settings.SULPUB_ID.PUB_URI}/#{new_pub.id}")
        )
        expect(response.body).to eq(new_pub.pub_hash.to_json)
      end
    end
  end
  # end describe POST

  describe 'Update existing contribution records via PATCH' do
    let(:http_request) { put :update, body: request_data.to_json, params: { format: 'json' } }

    context 'errors' do
      it_behaves_like 'it issues an error without author params'
      it_behaves_like 'it issues errors when sul_author_id does not exist'
      it_behaves_like 'it issues errors for cap_profile_id'
      it_behaves_like 'it handles invalid authorship attributes'

      it 'returns 500 error when publication contribution fails to save' do
        # Mock a publication in the valid request data so it fails to save.
        request_data = valid_data_for_post.merge(sul_author_hash)
        pub = Publication.find(request_data[:sul_pub_id])
        expect(pub).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved.new(pub))
        expect(Publication).to receive(:find).with(pub.id).and_return(pub)
        post :create, body: request_data.to_json, params: { format: 'json' }
        expect(response.status).to eq 500
      end

      context 'if there are contribution record errors' do
        let(:request_data) { update_authorship_for_pub_with_contributions }

        it 'returns 404 with error message for missing contributions' do
          # Although the request is valid and should find an existing
          # contribution, mock the response to ensure it's empty:
          expect(Contribution).to receive(:where).and_return([])
          http_request
          expect(response.status).to eq 404
          result = JSON.parse(response.body)
          expect(result['error']).to include('no contributions', existing_contrib.author.id.to_s, existing_contrib.publication.id.to_s)
        end

        it 'returns 500 with error message for duplicate contributions' do
          # Although the request is valid and should find an existing
          # contribution, mock the response to ensure it has duplicates:
          expect(Contribution).to receive(:where).and_return(
            [existing_contrib, existing_contrib]
          )
          http_request
          result = JSON.parse(response.body)
          expect(response.status).to eq 500
          expect(result['error']).to include('multiple contributions', existing_contrib.author.id.to_s, existing_contrib.publication.id.to_s)
        end
      end

      context 'if there are publication errors' do
        let(:no_pub_params) { sul_author_hash.merge(base_data) }
        let(:id) { '0' }

        it 'returns 400 when publication parameters are missing' do
          post :create, body: no_pub_params.to_json, params: { format: 'json' }
          expect(response.status).to eq 400
          result = JSON.parse(response.body)
          expect(result['error']).to include('You have not supplied any publication identifier', 'sul_pub_id', 'pmid', 'sw_id', 'wos_uid')
        end

        context 'matching WoS publication is not found for provided WoS UID' do
          it 'returns 404 with error message' do
            expect(WebOfScience.harvester).to receive(:author_uid).with(Author, id)
            allow(WebOfScienceSourceRecord).to receive(:find_by).with(uid: id).and_return(build(:web_of_science_source_record))
            # in this case we have a WoS Source Record for id = 0, but there is no matching publication in the database
            post :create, body: no_pub_params.merge(wos_uid: id).to_json, params: { format: 'json' }
            result = JSON.parse(response.body)
            expect(result['error']).to eq("A matching publication record for WOS_UID:#{id} was not found in the publication table.")
            expect(response.status).to eq 404
          end
        end

        context 'returns 404 with error message for invalid' do
          it 'sul_pub_id' do
            post :create, body: no_pub_params.merge(sul_pub_id: id).to_json, params: { format: 'json' }
            result = JSON.parse(response.body)
            expect(result['error']).to include(id, 'does not exist')
            expect(response.status).to eq 404
          end
          it 'pmid' do
            expect(Publication).to receive(:find_or_create_by_pmid)
            post :create, body: no_pub_params.merge(pmid: id).to_json, params: { format: 'json' }
            result = JSON.parse(response.body)
            expect(result['error']).to include(id, 'was not found')
            expect(response.status).to eq 404
          end
          it 'sw_id' do
            expect(Publication).to receive(:find_by).with(sciencewire_id: id)
            expect(SciencewireSourceRecord).to receive(:get_pub_by_sciencewire_id)
            post :create, body: no_pub_params.merge(sw_id: id).to_json, params: { format: 'json' }
            result = JSON.parse(response.body)
            expect(result['error']).to include(id, 'was not found')
            expect(response.status).to eq 404
          end
          it 'wos_uid' do
            expect(WebOfScience.harvester).to receive(:author_uid).with(Author, id)
            # in this case we have no WoS Source Record for id = 0
            post :create, body: no_pub_params.merge(wos_uid: id).to_json, params: { format: 'json' }
            result = JSON.parse(response.body)
            expect(result['error']).to include(id, 'A WebOfScienceSourceRecord was not found')
            expect(response.status).to eq 404
          end
        end
      end
    end

    context 'it updates an existing contribution' do
      # Convenience let! methods to store values for comparisons, using the
      # pub.pub_hash rather than the contrib_before object to be sure this
      # spec covers all the update ops that modify the pub.pub_hash.  Don't be
      # tempted to use the convenience methods used for all the other specs.
      # All of these must use `let!` so they execute before any http_request
      # in each example.
      let!(:contrib_before) do
        expect(existing_contrib.featured).to be true
        expect(existing_contrib.status).to eq 'approved'
        expect(existing_contrib.visibility).to eq 'public'
        existing_contrib
      end
      let!(:authorship_array) { contrib_before.publication.pub_hash[:authorship] }
      let!(:authorship_before) do
        authorship_matches = authorship_array.select do |a|
          a[:sul_author_id] == contrib_before.author.id ||
            a[:cap_profile_id] == contrib_before.author.cap_profile_id
        end
        expect(authorship_matches.length).to eq 1
        authorship_matches.first
      end
      let(:request_data) { update_authorship_for_pub_with_contributions }

      it 'does not create a new contribution' do
        expect { http_request }.not_to change(Contribution, :count)
        expect(response.status).to eq 202
      end

      it 'updates all contribution attributes' do
        http_request
        existing_contrib.reload
        expect(request_data).to include(featured: !be_nil, status: be_present, visibility: be_present)
        expect(existing_contrib.featured).to be request_data[:featured]
        expect(existing_contrib.status).to eq request_data[:status]
        expect(existing_contrib.visibility).to eq request_data[:visibility]
      end

      it 'updates the pub hash authorship attributes' do
        http_request
        # Expect no change in the number of contributions, only a
        # change in the attributes of the contribution updated.  In this
        # spec, the attributes must be checked in the response.
        result = JSON.parse(response.body)
        result_authorship = result['authorship']
        expect(result_authorship.length).to eq(authorship_array.length)
        authorship_matches = result_authorship.select do |a|
          a['sul_author_id'] == request_data[:sul_author_id] ||
            a['cap_profile_id'] == request_data[:cap_profile_id]
        end
        expect(authorship_matches.length).to eq 1
        authorship = authorship_matches.first
        expect(authorship).not_to eq(authorship_before)
        expect(request_data).to include(featured: !be_nil, status: be_present, visibility: be_present)
        expect(authorship).to include('featured' => request_data[:featured], 'status' => request_data[:status], 'visibility' => request_data[:visibility])
      end
    end

    context 'to update featured contribution attribute' do
      let(:request_data) { existing_contrib_ids.merge(featured: false) }
      it 'sets the featured flag only, leaving others fields alone' do
        expect(request_data).not_to include(:status, :visibility)
        http_request
        expect { existing_contrib.reload }.not_to change { [existing_contrib.visibility, existing_contrib.status] }
        expect(existing_contrib.featured).to be false
        expect(response.status).to eq 202
      end
    end

    context 'to update status contribution attribute' do
      let(:request_data) { existing_contrib_ids.merge(status: 'denied') }
      it 'sets status only, leaving other fields alone' do
        expect(request_data).not_to include(:featured, :visibility)
        http_request
        expect { existing_contrib.reload }.not_to change { [existing_contrib.visibility, existing_contrib.featured] }
        expect(existing_contrib.status).to eq 'denied'
        expect(response.status).to eq 202
      end
    end

    context 'to update visibility contribution attribute' do
      let(:request_data) { existing_contrib_ids.merge(visibility: 'private') }
      it 'sets visibility only, leaving other fields alone' do
        expect(request_data).not_to include(:featured, :status)
        http_request
        expect { existing_contrib.reload }.not_to change { [existing_contrib.status, existing_contrib.featured] }
        expect(existing_contrib.visibility).to eq 'private'
        expect(response.status).to eq 202
      end
    end

    context 'with allcaps or mixed case strings' do
      let(:request_data) { existing_contrib_ids.merge(visibility: 'PUBLIC', status: 'New') }
      it 'downcases authorship hash appropriately' do
        http_request
        expect { existing_contrib.reload }.not_to change { [existing_contrib.featured] }
        expect(existing_contrib.status).to eq 'new'
        expect(existing_contrib.visibility).to eq 'public'
        expect(response.status).to eq 202
      end
    end
  end
  # end describe PATCH
end
