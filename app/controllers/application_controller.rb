class ApplicationController < ActionController::Base
  protect_from_forgery

  include Squash::Ruby::ControllerMethods
  enable_squash_client

  def check_authorization
    head :forbidden unless env['HTTP_CAPKEY'] == Settings.API_KEY
  end
end
