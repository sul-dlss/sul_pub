
describe AuthorsController do
  let(:author) { create(:author) }
  describe 'POST harvest' do
    it 'ensures authorization header is present' do
      post :harvest, cap_profile_id: 123
      expect(response.status).to eq 401
    end
    context 'when authorized' do
      before do
        expect(controller).to receive(:check_authorization).and_return(true)
      end
      it 'ensures the request is json' do
        post :harvest, cap_profile_id: 123
        expect(response.status).to eq 406
      end
      it 'enqueues an AuthorHarvestJob with an Author' do
        ActiveJob::Base.queue_adapter = :test
        expect do
          post :harvest, cap_profile_id: author.cap_profile_id, format: :json
          expect(response.status).to eq 202
        end.to have_enqueued_job(AuthorHarvestJob).with(author.cap_profile_id.to_s, harvest_alternate_names: false)
      end
      it 'enqueues an AuthorHarvestJob with an Author and altNames parameter' do
        ActiveJob::Base.queue_adapter = :test
        expect do
          post :harvest, cap_profile_id: author.cap_profile_id, format: :json, altNames: 'true'
          expect(response.status).to eq 202
        end.to have_enqueued_job(AuthorHarvestJob).with(author.cap_profile_id.to_s, harvest_alternate_names: true)
      end
    end
  end
end
