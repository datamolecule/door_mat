class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include DoorMat::Controller
  before_action :require_valid_session
  before_action :require_confirmed_email

end
