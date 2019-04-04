class AuthorsController < ApplicationController
  before_action :check_authorization
  before_action :ensure_json_request

  # request an immediate harvest of this user's profile
  # POST /authors/:cap_profile_id/harvest.json
  def harvest
    if AuthorHarvestJob.perform_later(author_params[:cap_profile_id], harvest_alternate_names: alt_names)
      render json: {
        response: "Harvest for author #{params[:cap_profile_id]} was successfully created."
      }, status: :accepted
    else
      render json: {
        error: "Harvest for author #{params[:cap_profile_id]} failed."
      }, status: :error
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
end
