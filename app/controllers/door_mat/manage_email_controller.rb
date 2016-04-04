module DoorMat
  class ManageEmailController < DoorMat::ApplicationController
    before_action :require_password_reconfirm
    before_action :require_confirmed_email
    before_action :update_session_last_activity_time

    def new
      @email = DoorMat::Email.new
    end

    def create
      @email = DoorMat::Email.for(manage_email_params[:address])

      if DoorMat::Process::ManageEmail.add(@email, DoorMat::Session.current_session.actor, self)
        flash[:notice] = I18n.t('door_mat.manage_email.email_added')

        redirect_to config_url_redirect(:add_email_success_url)
      else
        render :new
      end
    end

    def destroy
      encoded_address = params[:email]
      email = DoorMat::Session.current_session.actor.email_from_urlsafe_encoded(encoded_address)

      if email.blank?
        flash[:alert] = I18n.t('door_mat.manage_email.could_not_delete')
      elsif 1 == DoorMat::Session.current_session.actor.emails.count
        flash[:alert] = I18n.t('door_mat.manage_email.could_not_delete_only_email')
      elsif email == DoorMat::Session.current_session.email
        flash[:alert] = I18n.t('door_mat.manage_email.could_not_delete_current_email')
      elsif email.primary?
        flash[:alert] = I18n.t('door_mat.manage_email.can_not_delete_primary')
      else
        email.destroy!
        flash[:notice] = I18n.t('door_mat.manage_email.email_deleted')
      end

      redirect_to config_url_redirect(:destroy_email_redirect_url)
    end

    def set_primary_email
      encoded_address = params[:email]
      if DoorMat::Process::ManageEmail.set_primary(encoded_address, DoorMat::Session.current_session.actor)
        flash[:notice] = I18n.t('door_mat.manage_email.primary_email_updated')
      else
        flash[:alert] = I18n.t('door_mat.manage_email.could_not_update_primary_email')
      end

      redirect_to config_url_redirect(:set_primary_email_redirect_url)
    end

    private

    def manage_email_params
      params.require(:email).permit(:address)
    end

  end
end
