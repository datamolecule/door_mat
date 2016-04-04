module DoorMat
  class ReconfirmPasswordController < DoorMat::ApplicationController
    def new
      @current_session_email = nil

      # Following a
      # require_password_reconfirm, provide the email associated with
      # the current session.
      # This convenience could be considered a leak of information
      # so it is disabled by default.
      if DoorMat.configuration.leak_email_address_at_reconfirm
        @current_session_email = DoorMat::Session.current_session.email.address
      end
    end

    def create
      password = params[:password]
      if DoorMat::Session.current_session.reconfirm_password(password)
        destination_of_redirect = session.delete(:redirect_to) || config_url_redirect(:sign_in_success_url)
        redirect_to destination_of_redirect
      else
        render :new
      end
    end

  end
end