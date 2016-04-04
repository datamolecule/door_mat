module DoorMat
  class ApplicationController < ActionController::Base

    # Make the engine use the main_app layouts/application file and helpers
    layout 'layouts/application'
    helper Rails.application.helpers

    include DoorMat::Controller
    before_action :require_valid_session

    protect_from_forgery with: :exception

  end
end
