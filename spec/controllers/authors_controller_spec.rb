# frozen_string_literal: true

describe AuthorsController do
  let(:author) { create(:author) }

  describe 'POST harvest' do
    it 'ensures authorization header is present' do
      post :harvest, params: { cap_profile_id: 123 }
      expect(response).to have_http_status :unauthorized
    end

    context 'when authorized' do
      before do
        expect(controller).to receive(:check_authorization).and_return(true)
      end

      it 'ensures the request is json' do
        post :harvest, params: { cap_profile_id: 123 }
        expect(response).to have_http_status :not_acceptable
      end

      it 'enqueues an AuthorHarvestJob with an Author' do
        ActiveJob::Base.queue_adapter = :test
        expect do
          post :harvest, params: { cap_profile_id: author.cap_profile_id, format: :json }
          expect(response).to have_http_status :accepted
        end.to have_enqueued_job(AuthorHarvestJob).with(author.cap_profile_id.to_s)
      end
    end
  end
end
