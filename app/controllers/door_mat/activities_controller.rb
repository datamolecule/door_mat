module DoorMat
  class ActivitiesController < DoorMat::ApplicationController
    before_action :require_password_reconfirm
    before_action :require_confirmed_email, except: [:resend_email_confirmation, :confirm_email]
    before_action :update_session_last_activity_time

    def resend_email_confirmation
      actor = DoorMat::Session.current_session.actor
      encoded_email = params[:email]

      email = actor.email_from_urlsafe_encoded(encoded_email)
      if email.blank?
        redirect_to config_url_redirect(:resend_email_confirmation_redirect_url)
      else
        if email.not_confirmed?
          DoorMat::ActivityConfirmEmail.for(email, self)
          redirect_to config_url_redirect(:resend_email_confirmation_redirect_url)
        else
          redirect_to config_url_redirect(:confirm_email_success_url)
        end
      end
    end

    # :email is a Base64.urlsafe_encode64 of a user email address
    def confirm_email
      before_confirm_email

      actor = DoorMat::Session.current_session.actor
      token = params[:token]
      encoded_address = params[:email]

      actor.with_lock do
        actor.confirm_email_activities.each do |activity|
          if activity.input_valid?(token, encoded_address)
            if actor.has_primary_email?
              activity.email.confirmed!
            else
              activity.email.primary!
            end
            activity.done!
            flash[:notice] = "Email was confirmed."

            redirect_to config_url_redirect(:confirm_email_success_url)
            after_confirm_email(activity.email)
            return
          end
        end
      end

      after_failed_confirm_email
      lockdown(log_message: 'ERROR: failed request to confirm_email')
    end

    def download_recovery_key
      before_download_recovery_key

      actor = DoorMat::Session.current_session.actor
      token = params[:token]
      disposition = params[:disposition]

      disposition = 'attachment' unless disposition.to_s == 'inline'

      actor.with_lock do
        actor.download_recovery_key_activities.each do |activity|
          if activity.input_valid?(token)

            recovery_key = DoorMat::Session.current_session.package_recovery_key

            send_data recovery_key, filename: "recovery_key_#{Date.current.strftime("%Y%m%d")}.txt", disposition: disposition

            activity.done!
            flash[:notice] = "Keep this recovery key file safely, you will need it to recover your data in case you forget your password."
            after_download_recovery_key
            return
          end
        end
      end

      after_failed_download_recovery_key
      lockdown(log_message: 'ERROR: failed request to download_recovery_key')
    end

    private

    def before_confirm_email
      DoorMat.configuration.event_hook_before_confirm_email.each {|prc| prc.call}
    end
    def after_confirm_email(email)
      DoorMat.configuration.event_hook_after_confirm_email.each {|prc| prc.call(email)}
    end
    def after_failed_confirm_email
      DoorMat.configuration.event_hook_after_failed_confirm_email.each {|prc| prc.call}
    end

    def before_download_recovery_key
      DoorMat.configuration.event_hook_before_download_recovery_key.each {|prc| prc.call}
    end
    def after_download_recovery_key
      DoorMat.configuration.event_hook_after_download_recovery_key.each {|prc| prc.call}
    end
    def after_failed_download_recovery_key
      DoorMat.configuration.event_hook_after_failed_download_recovery_key.each {|prc| prc.call}
    end

  end
end
