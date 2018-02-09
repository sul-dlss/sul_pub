class AuthorsController < ApplicationController
  before_action :check_authorization
  before_action :ensure_json_request

  # POST /authors/:cap_profile_id/harvest.json
  def harvest
    author = Author.find_by(cap_profile_id: author_params[:cap_profile_id])
    author ||= Author.fetch_from_cap_and_create(author_params[:cap_profile_id])
    render_failure unless author.is_a?(Author)

    job_queued = false
    if Settings.SCIENCEWIRE.enabled
      job_queued = ScienceWire::AuthorHarvestJob.perform_later(author, alternate_names: alt_names)
    end
    if Settings.WOS.enabled
      job_queued = WebOfScience::AuthorHarvestJob.perform_later(author, alternate_names: alt_names)
    end
    if job_queued
      render_accepted
    else
      render_failure
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def author_params
      params.permit(:cap_profile_id, :altNames, :format)
    end

    ##
    # @return [Boolean]
    def alt_names
      author_params[:altNames] == 'true'
    end

    def ensure_json_request
      return if request.format == :json
      render nothing: true, status: :not_acceptable
    end

    def render_accepted
      render json: {
        response: "Harvest for author #{params[:cap_profile_id]} was successfully created."
      }, status: :accepted
    end

    def render_failure
      render json: {
        error: "Harvest for author #{params[:cap_profile_id]} failed."
      }, status: :error
    end
end
