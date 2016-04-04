module DoorMat
  class ChangePasswordController < DoorMat::ApplicationController
    before_action :require_confirmed_email
    before_action :update_session_last_activity_time

    def new
      @change_password = DoorMat::ChangePassword.new
    end

    def create
      @change_password = DoorMat::ChangePassword.new(change_password_params)
      actor = DoorMat::Session.current_session.actor

      if @change_password.valid? && DoorMat::Process::ActorPasswordChange.with(actor, @change_password.new_password, @change_password.old_password)
        DoorMat::Session.current_session.set_up(cookies)
        flash[:notice] = I18n.t('door_mat.change_password.success')

        redirect_to config_url_redirect(:change_password_success_url)
      else
        flash[:alert] = I18n.t('door_mat.change_password.failed')
        render :new
      end
    end

    private

    def change_password_params
      params.require(:change_password).permit(:old_password, :new_password, :new_password_confirmation)
    end

  end
end
