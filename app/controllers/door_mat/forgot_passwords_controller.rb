module DoorMat
  class ForgotPasswordsController < DoorMat::ApplicationController
    skip_before_action :require_valid_session, :only => [:new, :create, :choose_new_password, :reset_password]

    def new
      @forgot_password = DoorMat::ForgotPassword.new
    end

    # :email is a Base64.urlsafe_encode64 of a user email address
    def create
      @forgot_password = DoorMat::ForgotPassword.new(forgot_password_params)
      @forgot_password.password = @forgot_password.password_confirmation = '-'

      if @forgot_password.valid?
        DoorMat::Process::ResetPassword.for(@forgot_password.email, self)

        # No matter what, requester gets the same response
        redirect_to config_url_redirect(:forgot_password_verification_mail_sent_url)
      else
        render :new
      end
    end

    def choose_new_password
      @forgot_password = DoorMat::ForgotPassword.new(choose_new_password_params)
      @forgot_password.email = DoorMat::Email.decode_urlsafe(@forgot_password.email)
    end

    def reset_password
      @forgot_password = DoorMat::ForgotPassword.new(reset_password_params)
      if @forgot_password.valid?
        if DoorMat::Process::ResetPassword.with(@forgot_password)
        redirect_to door_mat.sign_in_url
        else
          flash[:alert] = I18n.t('door_mat.forgot_password.make_new_request')
          redirect_to door_mat.forgot_password_url
        end

      else
        render :choose_new_password
      end
    end

    private

    def forgot_password_params
      params.require(:forgot_password).permit(:email)
    end
    def choose_new_password_params
      params.permit(:email, :token)
    end
    def reset_password_params
      params.require(:forgot_password).permit(:email, :password, :password_confirmation, :recovery_key, :token)
    end

  end
end
