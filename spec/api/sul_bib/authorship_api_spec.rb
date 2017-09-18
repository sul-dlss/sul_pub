require 'spec_helper'
SingleCov.covered! file: 'app/api/sul_bib/authorship_api.rb'

describe SulBib::API, :vcr do
  let(:headers) { { 'HTTP_CAPKEY' => Settings.API_KEY, 'CONTENT_TYPE' => 'application/json' } }
  # The publication is defined in /spec/factories/publication.rb
  let(:publication) { create :publication }
  # The author is defined in /spec/factories/author.rb
  let(:author) { create :author }
  # These authorships can be merged with any contribution hash
  let(:cap_author_hash) do
    { cap_profile_id: author.cap_profile_id }
  end
  let(:sul_author_hash) do
    { sul_author_id: author.id }
  end
  let(:contribution_count) { 2 }
  # let is lazy-evaluated: it is evaluated the first time it's method is invoked.
  # Use let! to force the method's invocation before each example.
  let!(:publication_with_contributions) do
    # The publication is defined in /spec/factories/publication.rb
    # The contributions are are defined in /spec/factories/contribution.rb
    pub = create :publication_with_contributions, contributions_count: contribution_count
    # FactoryGirl knows nothing about the Publication.pub_hash sync issue, so
    # it must be forced to update that data with the contributions.
    pub.pubhash_needs_update!
    pub.save # to update the pub.pub_hash
    pub
  end
  let(:valid_data_for_post) do
    {
      # author_hash is merged here
      sul_pub_id: publication.id,
      featured: false,
      status: 'denied',
      visibility: 'private',
    }
  end
  let(:new_authorship_for_pub_with_contributions) do
    # The contribution is defined in /spec/factories/contribution.rb
    # status 'approved', visibility 'public', featured true
    # In this submission, use different values.
    {
      # author_hash is merged here
      sul_pub_id: publication_with_contributions.id,
      featured: false,
      status: 'denied',
      visibility: 'private'
    }
  end
  let(:authorship_for_sw_id) do
    {
      # author_hash is merged here
      sw_id: '10379039',
      featured: false,
      status: 'denied',
      visibility: 'private'
    }
  end
  let(:authorship_for_pmid) do
    {
      # author_hash is merged here
      pmid: '23684686',
      featured: false,
      status: 'denied',
      visibility: 'private'
    }
  end
  let(:existing_contrib) do
    # The contribution is defined in /spec/factories/contribution.rb
    # status 'approved', visibility 'public', featured true
    pub = publication_with_contributions
    pub.contributions.first
  end
  let(:existing_contrib_ids) do
    {
      # author_hash is NOT merged here, because this data is
      # concerned with an existing contribution.
      sul_author_id: existing_contrib.author.id,
      sul_pub_id: existing_contrib.publication.id
    }
  end
  # The contribution is defined in /spec/factories/contribution.rb
  # status 'approved', visibility 'public', featured true
  # In the submissions below, use different values.
  let(:update_authorship_for_pub_with_contributions) do
    existing_contrib_ids.merge(
      featured: false,
      status: 'denied',
      visibility: 'private'
    )
  end
  # For PATCH, the attribute params are optional, so only
  # include those to be updated.
  let(:patch_featured_for_pub_with_contributions) do
    existing_contrib_ids.merge(
      featured: false
    )
  end
  let(:patch_status_for_pub_with_contributions) do
    existing_contrib_ids.merge(
      status: 'denied'
    )
  end
  let(:patch_visibility_for_pub_with_contributions) do
    existing_contrib_ids.merge(
      visibility: 'private'
    )
  end

  # The shared examples require the calling example (or it's context)
  # to define a let(:http_request) that specifies the request
  # method path, json, headers
  # e.g.
  # let(:http_request) do
  #   post '/authorship', json_data, headers
  # end

  shared_examples 'it is successful' do
    it 'has response code < 300' do
      http_request # defined in calling context
      expect(response.status).to be < 300
    end
  end

  shared_examples 'it creates a new contribution' do
    it 'it increases number of contribution records by one' do
      expect do
        http_request # defined in calling context
      end.to change(Contribution, :count).by(1)
    end
  end

  shared_examples 'it creates new contributions and publications' do
    context 'with no other contributions' do
      let(:request_data) do
        # merge either sul_author_hash or cap_author_hash
        valid_data_for_post.merge(author_hash)
      end
      it_behaves_like 'it is successful'
      it_behaves_like 'it creates a new contribution'
    end # context 'with no other contributions'

    context 'with prior contributions' do
      let(:request_data) do
        # merge either sul_author_hash or cap_author_hash
        new_authorship_for_pub_with_contributions.merge(author_hash)
      end
      it_behaves_like 'it is successful'
      it_behaves_like 'it creates a new contribution'
      it 'creates a new authorship record without overwriting existing authorship records' do
        http_request
        count = contribution_count + 1
        expect(publication_with_contributions.contributions(true).size).to eq(count)
      end
      it 'increases number of contribution records for specified publication by one' do
        expect do
          http_request
        end.to change(publication_with_contributions.contributions, :count).by(1)
      end
      it 'creates only one contribution' do
        http_request
        count = Contribution.where(
          publication_id: publication_with_contributions.id,
          author_id: author.id).count
        expect(count).to eq 1
      end
      it 'creates a contribution record with matching attributes' do
        http_request
        contribution = Contribution.where(
          publication_id: publication_with_contributions.id,
          author_id: author.id).first
        expect(contribution.featured).to be false
        expect(contribution.status).to eq('denied')
        expect(contribution.visibility).to eq('private')
      end
      it 'adds the authorship entry to the pub_hash for the publication' do
        http_request
        publication_with_contributions.reload
        authorship = publication_with_contributions.pub_hash[:authorship]
        expect(authorship.any? { |a| a[:sul_author_id] == author.id }).to be true
      end
      it 'adds one authorship entry to response pub_hash' do
        # This specifically checks the response data, whereas the prior
        # spec checks the data model.
        http_request
        # Expect a change in the number of contributions
        result_pubhash = JSON.parse(response.body)
        result_authorship = result_pubhash['authorship']
        expect(result_authorship.length).to eq(contribution_count + 1)
        authorship_matches = result_authorship.select do |a|
          a['sul_author_id'] == author.id
        end
        expect(authorship_matches.length).to eq(1)
        authorship = authorship_matches.first
        expect(authorship['status']).to eq 'denied'
        expect(authorship['featured']).to be false
        expect(authorship['visibility']).to eq 'private'
      end
    end # context 'with prior contributions'

    context 'for a new PubMed publication' do
      let(:request_data) do
        # merge either sul_author_hash or cap_author_hash
        authorship_for_pmid.merge(author_hash)
      end
      let(:new_pub) { Publication.last }
      # Use `let!` to issue HTTP request and check result before each example.
      let!(:result) do
        http_request
        expect(response.body).to eq(new_pub.pub_hash.to_json)
        JSON.parse(response.body)
      end

      it 'adds new publication' do
        expect(result['pmid']).to eq(request_data[:pmid])
        expect(result['authorship'].length).to eq 1
        contribution = Contribution.where(
          publication_id: new_pub.id,
          author_id: author.id).first
        expect(contribution.featured).to eq(request_data[:featured])
        expect(contribution.status).to eq(request_data[:status])
        expect(contribution.visibility).to eq(request_data[:visibility])
      end

      it 'adds proper identifiers section' do
        pub_ids = result['identifier']
        # Check the PMID, e.g.
        # {"type"=>"PMID", "id"=>"23684686", "url"=>"https://www.ncbi.nlm.nih.gov/pubmed/23684686"}
        pmid_hash = pub_ids.find { |id| id['type'] == 'PMID' }
        expect(pmid_hash).to be_instance_of Hash
        pmid = request_data[:pmid]
        expect(pmid_hash['type']).to eq('PMID')
        expect(pmid_hash['id']).to eq(pmid)
        expect(pmid_hash['url']).to eq("https://www.ncbi.nlm.nih.gov/pubmed/#{pmid}")
        # Check the SULPubId, e.g.
        # {:type=>"SULPubId", :id=>"2355", :url=>"https://sulcap.stanford.edu/publications/2355"}],
        sul_hash = pub_ids.find { |id| id['type'] == 'SULPubId' }
        expect(sul_hash).to be_instance_of Hash
        sul_pub_id = Publication.last.id.to_s
        expect(sul_hash['type']).to eq('SULPubId')
        expect(sul_hash['id']).to eq(sul_pub_id)
        expect(sul_hash['url']).to eq("#{Settings.SULPUB_ID.PUB_URI}/#{sul_pub_id}")
      end
    end # context 'for a new PubMed publication'

    context 'for a new ScienceWire publication' do
      let(:request_data) do
        # merge either sul_author_hash or cap_author_hash
        authorship_for_sw_id.merge(author_hash)
      end
      let(:new_pub) { Publication.last }
      # Use `let!` to issue HTTP request and check result before each example.
      let!(:result) do
        http_request # defined in context, uses json_data
        expect(response.body).to eq(new_pub.pub_hash.to_json)
        JSON.parse(response.body)
      end

      it 'adds new ScienceWire publication' do
        expect(result['sw_id']).to eq(request_data[:sw_id])
        expect(result['authorship'].length).to eq 1
        expect(result['authorship'][0]['sul_author_id']).to eq(author.id)
        contribution = Contribution.where(
          publication_id: new_pub.id,
          author_id: author.id).first
        expect(contribution.featured).to eq(request_data[:featured])
        expect(contribution.status).to eq(request_data[:status])
        expect(contribution.visibility).to eq(request_data[:visibility])
      end

      it 'adds new ScienceWire publication with proper identifiers section' do
        pub_ids = result['identifier']
        # This doesn't result is a clearly identified ScienceWire identifier, e.g.
        # {"type"=>"PublicationItemID", "id"=>"10379039"}
        item_hash = pub_ids.find { |id| id['type'] == 'PublicationItemID' }
        expect(item_hash).to be_instance_of Hash
        swid = request_data[:sw_id]
        expect(item_hash['type']).to eq('PublicationItemID')
        expect(item_hash['id']).to eq(swid)
        # Check the SULPubId, e.g.
        # {:type=>"SULPubId", :id=>"2355", :url=>"http://sulcap.stanford.edu/publications/2355"}],
        sul_hash = pub_ids.find { |id| id['type'] == 'SULPubId' }
        expect(sul_hash).to be_instance_of Hash
        sul_pub_id = Publication.last.id.to_s
        expect(sul_hash['type']).to eq('SULPubId')
        expect(sul_hash['id']).to eq(sul_pub_id)
        expect(sul_hash['url']).to eq("#{Settings.SULPUB_ID.PUB_URI}/#{sul_pub_id}")
      end
    end # context 'for a new ScienceWire publication'
  end

  shared_examples 'it updates an existing contribution' do
    # Convenience let! methods to store values for comparisons, using the
    # pub.pub_hash rather than the contrib_before object to be sure this
    # spec covers all the update ops that modify the pub.pub_hash.  Don't be
    # tempted to use the convenience methods used for all the other specs.
    # All of these must use `let!` so they execute before any http_request
    # in each example.
    let!(:contrib_before) do
      contrib_before = existing_contrib
      expect(contrib_before.featured).to be true
      expect(contrib_before.status).to eq 'approved'
      expect(contrib_before.visibility).to eq 'public'
      contrib_before
    end
    let!(:authorship_array) do
      pub = contrib_before.publication
      pub.pub_hash[:authorship]
    end
    let!(:authorship_before) do
      authorship_matches = authorship_array.select do |a|
        a[:sul_author_id] == contrib_before.author.id ||
          a[:cap_profile_id] == contrib_before.author.cap_profile_id
      end
      expect(authorship_matches.length).to eq(1)
      authorship_matches.first
    end
    let!(:authorship_count) do
      authorship_array.length
    end

    it_behaves_like 'it is successful'

    it 'does not create a new contribution' do
      expect do
        http_request # defined in context, uses json_data
      end.not_to change(Contribution, :count)
    end

    it 'updates all contribution attributes' do
      http_request # defined in context, uses json_data
      existing_contrib.reload
      expect(request_data[:featured]).not_to be_nil
      expect(existing_contrib.featured).to be request_data[:featured]
      expect(request_data[:status]).not_to be_nil
      expect(existing_contrib.status).to eq request_data[:status]
      expect(request_data[:visibility]).not_to be_nil
      expect(existing_contrib.visibility).to eq request_data[:visibility]
    end

    it 'updates the pub hash authorship attributes' do
      http_request # defined in context, uses json_data
      # Expect no change in the number of contributions, only a
      # change in the attributes of the contribution updated.  In this
      # spec, the attributes must be checked in the response.
      result_pubhash = JSON.parse(response.body)
      result_authorship = result_pubhash['authorship']
      expect(result_authorship.length).to eq(authorship_count)
      authorship_matches = result_authorship.select do |a|
        a['sul_author_id'] == request_data[:sul_author_id] ||
          a['cap_profile_id'] == request_data[:cap_profile_id]
      end
      expect(authorship_matches.length).to eq(1)
      authorship = authorship_matches.first
      expect(authorship).not_to eq(authorship_before)
      expect(request_data[:featured]).not_to be_nil
      expect(authorship['featured']).to eq request_data[:featured]
      expect(request_data[:status]).not_to be_nil
      expect(authorship['status']).to eq request_data[:status]
      expect(request_data[:visibility]).not_to be_nil
      expect(authorship['visibility']).to eq request_data[:visibility]
    end
  end # 'it updates an existing contribution'

  # ---
  # shared examples for failures

  shared_examples 'it issues errors without author params' do
    let(:request_data) { valid_data_for_post }
    it 'returns 400 with an error message' do
      http_request
      expect(response.status).to eq 400
      # Check error message for some details
      result = JSON.parse(response.body)
      expect(result['error']).not_to be_nil
      expect(result['error']).to include('sul_author_id')
      expect(result['error']).to include('cap_profile_id')
    end
  end # shared_examples 'it issues errors without author params'

  shared_examples 'it issues errors when sul_author_id does not exist' do
    let(:sul_author_id) { '999999' }
    let(:request_data) do
      valid_data_for_post.merge(
        sul_author_id: sul_author_id
      )
    end
    it 'returns 404 when it fails to find a sul_author_id' do
      http_request
      expect(response.status).to eq 404
      # Check error message for some details
      result = JSON.parse(response.body)
      expect(result['error']).not_to be_nil
      expect(result['error']).to include('sul_author_id')
      expect(result['error']).to include(sul_author_id)
    end
  end

  shared_examples 'it issues errors for cap_profile_id' do
    let(:cap_profile_id) { '999999' }
    let(:request_data) do
      valid_data_for_post.merge(
        cap_profile_id: cap_profile_id
      )
    end
    def check_response_error(code)
      expect(response.status).to eq code
      # Check error message for some details
      result = JSON.parse(response.body)
      expect(result['error']).not_to be_nil
      expect(result['error']).to include('cap_profile_id')
      expect(result['error']).to include(cap_profile_id)
    end
    it 'returns 404 when it fails to find a cap_profile_id' do
      http_request
      check_response_error 404
    end
    it 'returns 404 when it cannot retrieve a cap_profile_id' do
      expect(Author).to receive(:fetch_from_cap_and_create)
        .with(cap_profile_id)
        .and_return(nil)
      http_request
      check_response_error 404
    end
    it 'returns 500 when it finds duplicate authors for a cap_profile_id' do
      expect(Author).to receive(:where)
        .with(cap_profile_id: cap_profile_id)
        .and_return([author, author])
      http_request
      check_response_error 500
      result = JSON.parse(response.body)
      expect(result['error']).to include('multiple records')
    end
  end # shared_examples 'it issues errors for cap_profile_id'

  # When the database constraints for cap_profile_id are setup
  # correctly and the AuthorshipAPI uses cap_profile_id before sul_author_id
  # to find an author, it's virtually impossible to hit the errors tested
  # by these specs.  However, the database constraints do not, yet,
  # enforce NOT NULL and UNIQUE on the cap_profile_id.
  shared_examples 'it checks author for the correct cap_profile_id' do
    let(:cap_profile_id) { '999999' }
    let(:request_data) do
      valid_data_for_post.merge(
        cap_profile_id: cap_profile_id,
        sul_author_id: author.id
      )
    end
    it 'updates author without a cap_profile_id' do
      author.cap_profile_id = ''
      expect(Author).to receive(:where)
        .with(cap_profile_id: cap_profile_id)
        .and_return([author])
      http_request
      expect(author.cap_profile_id).to eq(cap_profile_id.to_i)
      # check_response_error 404
    end
    it 'returns 500 when author has a different cap_profile_id' do
      author.cap_profile_id = '666666'
      expect(Author).to receive(:where)
        .with(cap_profile_id: cap_profile_id)
        .and_return([author])
      http_request
      expect(response.status).to eq 500
      # Check error message for some details
      result = JSON.parse(response.body)
      expect(result['error']).not_to be_nil
      expect(result['error']).to include('different cap_profile_id')
      expect(result['error']).to include(cap_profile_id)
      expect(result['error']).to include(author.cap_profile_id.to_s)
      expect(result['error']).to include(author.id.to_s)
    end
  end # shared_examples 'it issues errors for cap_profile_id'

  # When the database constraints for cap_profile_id are setup
  # correctly and the AuthorshipAPI uses cap_profile_id before sul_author_id
  # to find an author, it's virtually impossible to hit the errors tested
  # by these specs.  However, the database constraints do not, yet,
  # enforce NOT NULL and UNIQUE on the cap_profile_id.
  shared_examples 'it checks author for a cap_profile_id' do
    let(:request_data) do
      author.cap_profile_id = ''
      author.save!
      valid_data_for_post.merge(
        sul_author_id: author.id
      )
    end
    it 'logs a warning for an author without a cap_profile_id' do
      expect(Rails.logger).to receive(:warn).once
      http_request
      expect(author.cap_profile_id).to be_nil
    end
  end # shared_examples 'it issues errors for cap_profile_id'

  shared_examples 'it handles invalid authorship attributes' do
    let(:request_data) do
      data = update_authorship_for_pub_with_contributions
      data[:visibility] = 'invalid value'
      data
    end
    it 'returns 406' do
      http_request
      expect(response.status).to eq 406
    end
  end # shared_examples 'it handles invalid authorship/contribution data'

  # ---
  # POST

  context 'POST /authorship' do
    context 'success' do
      let(:http_request) do
        post '/authorship', json_data, headers
        expect(response.status).to eq(201)
      end
      let(:json_data) { request_data.to_json }

      context 'with sul_author_id' do
        let(:author_hash) { sul_author_hash }
        it_behaves_like 'it creates new contributions and publications'
        # TODO: modifies existing contributions.
      end

      context 'with cap_profile_id' do
        let(:author_hash) { cap_author_hash }
        it_behaves_like 'it creates new contributions and publications'
        # TODO: modifies existing contributions.
      end

      context 'to update a contribution' do
        let(:request_data) { update_authorship_for_pub_with_contributions }
        it_behaves_like 'it updates an existing contribution'
      end
    end # context 'success'

    context 'failure' do
      # This http_request cannot expect a successful response.
      let(:http_request) do
        post '/authorship', json_data, headers
      end
      let(:json_data) { request_data.to_json }

      it_behaves_like 'it issues errors without author params'
      it_behaves_like 'it issues errors when sul_author_id does not exist'
      it_behaves_like 'it issues errors for cap_profile_id'
      it_behaves_like 'it checks author for the correct cap_profile_id'
      it_behaves_like 'it checks author for a cap_profile_id'
      it_behaves_like 'it handles invalid authorship attributes'

      it 'returns 500 error when publication contribution fails to save' do
        # Mock a publication in the valid request data so it fails to save.
        request_data = valid_data_for_post.merge(sul_author_hash)
        pub = Publication.find(request_data[:sul_pub_id])
        invalid = ActiveRecord::RecordNotSaved.new(pub)
        expect(pub).to receive(:save!).and_raise(invalid)
        expect(Publication).to receive(:find).with(pub.id.to_s).and_return(pub)
        post '/authorship', request_data.to_json, headers
        expect(response.status).to eq 500
      end

      context 'if there are publication errors' do
        let(:no_pub_params) do
          sul_author_hash.merge(
            featured: false,
            status: 'denied',
            visibility: 'private'
          )
        end
        it 'returns 400 when publication parameters are missing' do
          request_data = no_pub_params
          post '/authorship', request_data.to_json, headers
          expect(response.status).to eq 400
          # Check error message for some details
          result = JSON.parse(response.body)
          expect(result['error']).not_to be_nil
          expect(result['error']).to include('no valid publication identifier')
          expect(result['error']).to include('sul_pub_id')
          expect(result['error']).to include('pmid')
          expect(result['error']).to include('sw_id')
        end
        it 'returns 404 with error message for invalid sul_pub_id' do
          # expect(Publication).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
          sul_pub_id = '0'
          request_data = no_pub_params.merge(sul_pub_id: sul_pub_id)
          post '/authorship', request_data.to_json, headers
          expect(response.status).to eq 404
          # Check error message for some details
          result = JSON.parse(response.body)
          expect(result['error']).not_to be_nil
          expect(result['error']).to include(sul_pub_id)
          expect(result['error']).to include('does not exist')
        end
        it 'returns 404 with error message for invalid pmid' do
          expect(Publication).to receive(:find_or_create_by_pmid).and_return(nil)
          pmid = '0'
          request_data = no_pub_params.merge(pmid: pmid)
          post '/authorship', request_data.to_json, headers
          expect(response.status).to eq 404
          # Check error message for some details
          result = JSON.parse(response.body)
          expect(result['error']).not_to be_nil
          expect(result['error']).to include(pmid)
          expect(result['error']).to include('was not found')
        end
        it 'returns 404 with error message for invalid sw_id' do
          expect(Publication).to receive(:find_or_create_by_sciencewire_id).and_return(nil)
          sw_id = '0'
          request_data = no_pub_params.merge(sw_id: sw_id)
          post '/authorship', request_data.to_json, headers
          expect(response.status).to eq 404
          # Check error message for some details
          result = JSON.parse(response.body)
          expect(result['error']).not_to be_nil
          expect(result['error']).to include(sw_id)
          expect(result['error']).to include('was not found')
        end
      end # context 'if there are publication errors'
    end # context 'failure'
  end # context 'POST /authorship'

  # ---
  # PATCH

  context 'PATCH /authorship' do
    context 'success' do
      let(:http_request) do
        patch '/authorship', json_data, headers
        expect(response.status).to eq(200)
      end
      let(:json_data) { request_data.to_json }

      # The POST specs use either sul_author_id or cap_profile_id for creating
      # new contributions, because  it can create new authors for
      # cap_profile_id.  Testing the author parameters is not required for POST
      # requests that update a contribution (where the author already exists).
      # For all the PATCH specs, the contribution already exists, so testing
      # different author params is not important.

      context 'to update all contribution attributes' do
        let(:request_data) { update_authorship_for_pub_with_contributions }
        it_behaves_like 'it updates an existing contribution'
      end

      context 'to update featured contribution attribute' do
        let(:request_data) { patch_featured_for_pub_with_contributions }
        it 'sets featured only' do
          expect(request_data[:featured]).not_to be_nil
          expect(request_data[:status]).to be_nil
          expect(request_data[:visibility]).to be_nil
          http_request # defined in context, uses json_data
          existing_contrib.reload
          expect(existing_contrib.featured).to be request_data[:featured]
          expect(existing_contrib.status).to eq 'approved'
          expect(existing_contrib.visibility).to eq 'public'
        end
      end

      context 'to update status contribution attribute' do
        let(:request_data) { patch_status_for_pub_with_contributions }
        it 'sets status only' do
          expect(request_data[:featured]).to be_nil
          expect(request_data[:status]).not_to be_nil
          expect(request_data[:visibility]).to be_nil
          http_request # defined in context, uses json_data
          existing_contrib.reload
          expect(existing_contrib.featured).to be true
          expect(existing_contrib.status).to eq request_data[:status]
          expect(existing_contrib.visibility).to eq 'public'
        end
      end

      context 'to update visibility contribution attribute' do
        let(:request_data) { patch_visibility_for_pub_with_contributions }
        it 'sets visibility only' do
          expect(request_data[:featured]).to be_nil
          expect(request_data[:status]).to be_nil
          expect(request_data[:visibility]).not_to be_nil
          http_request # defined in context, uses json_data
          existing_contrib.reload
          expect(existing_contrib.featured).to be true
          expect(existing_contrib.status).to eq 'approved'
          expect(existing_contrib.visibility).to eq request_data[:visibility]
        end
      end
    end # context 'success'

    context 'failure' do
      # This http_request cannot expect a successful response.
      let(:http_request) do
        patch '/authorship', json_data, headers
      end
      let(:json_data) { request_data.to_json }

      it_behaves_like 'it issues errors without author params'
      it_behaves_like 'it issues errors when sul_author_id does not exist'
      it_behaves_like 'it issues errors for cap_profile_id'
      it_behaves_like 'it checks author for the correct cap_profile_id'
      it_behaves_like 'it checks author for a cap_profile_id'
      it_behaves_like 'it handles invalid authorship attributes'

      context 'if there are contribution record errors' do
        # Use an existing contribution data for the request, to ensure it
        # gets past all the parameter checks, and mock the Contribution.where
        # method to ensure it returns missing or invalid data.
        let(:request_data) { update_authorship_for_pub_with_contributions }
        def check_error_details(result)
          expect(result['error']).to include(existing_contrib.author.id.to_s)
          expect(result['error']).to include(existing_contrib.publication.id.to_s)
        end
        it 'returns 404 with error message for missing contributions' do
          # Although the request is valid and should find an existing
          # contribution, mock the response to ensure it's empty:
          expect(Contribution).to receive(:where).and_return([])
          http_request # defined in context, uses json_data
          expect(response.status).to eq 404
          # Check error message for some details
          result = JSON.parse(response.body)
          expect(result['error']).not_to be_nil
          expect(result['error']).to include('no contributions')
          check_error_details(result)
        end
        it 'returns 500 with error message for duplicate contributions' do
          # Although the request is valid and should find an existing
          # contribution, mock the response to ensure it has duplicates:
          expect(Contribution).to receive(:where).and_return(
            [existing_contrib, existing_contrib]
          )
          http_request # defined in context, uses json_data
          expect(response.status).to eq 500
          # Check error message for some details
          result = JSON.parse(response.body)
          expect(result['error']).not_to be_nil
          expect(result['error']).to include('multiple contributions')
          check_error_details(result)
        end
      end # context 'if there are contribution record errors'
    end # context 'failure'
  end # context 'PATCH /authorship'
end # end of the describe
