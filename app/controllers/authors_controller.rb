# frozen_string_literal: true

class AuthorsController < ApplicationController
  before_action :check_authorization
  before_action :ensure_json_request
  skip_forgery_protection # this controller only has API calls from profiles

  # request an immediate harvest of this user's profile
  # POST /authors/:cap_profile_id/harvest.json
  def harvest
    if AuthorHarvestJob.perform_later(author_params[:cap_profile_id])
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
    params.permit(:cap_profile_id, :format)
  end
end
