# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery # skipped in API only controllers (which happens to be all as of April 2019)

  def check_authorization
    return head :unauthorized if request.env['HTTP_CAPKEY'].nil?

    head :forbidden unless request.env['HTTP_CAPKEY'] == Settings.API_KEY
  end

  def ensure_request_body_exists
    return if request_body.present?

    head :bad_request
  end

  def ensure_json_request
    return if request.format == :json

    head :not_acceptable
  end

  def hashed_request
    JSON.parse(request_body).to_hash.deep_symbolize_keys # Avoid Hashie::Mash!
  end

  def request_body
    @request_body ||= request.body.read
  end

  # Used when we want to log something unusual in addition to sending an http response
  # @param [String] msg Message to log and send in response
  # @param [Symbol] code HTTP status code
  def log_and_error!(msg, code = :not_found)
    logger.error msg
    render json: { error: msg }.to_json, status: code, format: 'json'
  end
end
