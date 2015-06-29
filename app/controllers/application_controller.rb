class ApplicationController < ActionController::Base
  protect_from_forgery

  include Squash::Ruby::ControllerMethods
  enable_squash_client
end
