# frozen_string_literal: true

class DefaultController < ApplicationController
  def index
    render plain: 'SUL-Pub Citation Tracking System'
  end
end
