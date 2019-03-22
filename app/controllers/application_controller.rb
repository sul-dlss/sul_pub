class ApplicationController < ActionController::Base
  protect_from_forgery

  def check_authorization
    return head :unauthorized if request.env['HTTP_CAPKEY'].nil?
    head :forbidden unless request.env['HTTP_CAPKEY'] == Settings.API_KEY
  end
end
