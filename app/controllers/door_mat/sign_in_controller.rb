module DoorMat
  class SignInController < DoorMat::ApplicationController
    skip_before_action :require_valid_session, :only => [:new, :create, :destroy]

    def new
      @sign_in = DoorMat::SignIn.new
    end

    def create
      before_sign_in
      @sign_in = DoorMat::SignIn.new(sign_in_params)

      if @sign_in.valid? && DoorMat::Process::ActorSignIn.with(@sign_in.email, @sign_in.password, @sign_in.is_public?, @sign_in.remember_me?, request, cookies)
        destination_of_redirect = session.delete(:redirect_to) || config_url_redirect(:sign_in_success_url)
        reset_session

        redirect_to destination_of_redirect
        after_sign_in
      else
        @sign_in.add_generic_error_msg
        render :new
        after_failed_sign_in
      end
    end

    def destroy
      before_sign_out
      DoorMat::Session.clear_current_session
      DoorMat::Session.destroy_if_linked_to(cookies)

      reset_session
      redirect_to config_url_redirect(:sign_out_success_url)
      after_sign_out

    end

    private

    def sign_in_params
      params.require(:sign_in).permit(:email, :password, :is_public, :remember_me)
    end

    def before_sign_in
      DoorMat.configuration.event_hook_before_sign_in.each {|prc| prc.call}
    end
    def after_sign_in
      DoorMat.configuration.event_hook_after_sign_in.each {|prc| prc.call}
    end
    def after_failed_sign_in
      DoorMat.configuration.event_hook_after_failed_sign_in.each {|prc| prc.call}
    end
    def before_sign_out
      DoorMat.configuration.event_hook_before_sign_out.each {|prc| prc.call}
    end
    def after_sign_out
      DoorMat.configuration.event_hook_after_sign_out.each {|prc| prc.call}
    end

  end
end
