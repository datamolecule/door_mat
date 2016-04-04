module DoorMat
  class StaticController < DoorMat::ApplicationController
    skip_before_action :require_valid_session, :only => [:sign_out_success, :forgot_password_verification_mail_sent]
  end
end
