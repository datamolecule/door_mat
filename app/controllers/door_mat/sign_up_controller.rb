module DoorMat
  class SignUpController < DoorMat::ApplicationController
    skip_before_action :require_valid_session, :only => [:new, :create]

    def new
      @sign_up = DoorMat::SignUp.new
    end

    def create
      before_sign_up
      @sign_up = DoorMat::SignUp.new(sign_up_params)
      sign_up_failed = true

      if DoorMat.configuration.allow_sign_up && @sign_up.valid?

        if DoorMat.configuration.allow_sign_in_from_sign_up_form && DoorMat::Process::ActorSignIn.with(@sign_up.email, @sign_up.password, true, false, request, cookies)
          destination_of_redirect = session.delete(:redirect_to) || config_url_redirect(:sign_in_success_url)
          reset_session

          redirect_to destination_of_redirect
          after_sign_in
          sign_up_failed = false
        elsif DoorMat::Process::ActorSignUp.with(@sign_up.email, @sign_up.password, request, cookies, self)
          reset_session
          redirect_to config_url_redirect(:sign_up_success_url)
          after_sign_up
          sign_up_failed = false
        end

      end

      if sign_up_failed
        @sign_up.add_generic_error_msg
        render :new
        after_failed_sign_up
      end
    end

    private

    def sign_up_params
      params.require(:sign_up).permit(:email, :password, :password_confirmation)
    end

    def after_sign_in
      DoorMat.configuration.event_hook_after_sign_in.each {|prc| prc.call}
    end
    def before_sign_up
      DoorMat.configuration.event_hook_before_sign_up.each {|prc| prc.call}
    end
    def after_sign_up
      DoorMat.configuration.event_hook_after_sign_up.each {|prc| prc.call}
    end
    def after_failed_sign_up
      DoorMat.configuration.event_hook_after_failed_sign_up.each {|prc| prc.call}
    end

  end
end
