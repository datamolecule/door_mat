
module DoorMat
  module Controller

    def sign_out
      DoorMat::Session.clear_current_session
      DoorMat::Session.destroy_if_linked_to(cookies)

      DoorMat::AccessToken.clear_current_access_token
      DoorMat::AccessToken.destroy_if_linked_to(cookies)
    end

    def lockdown(**options)
      o = {
          log_level: :error,
          log_message: "LOCKDOWN: No log message specified",
          redirect_to: nil
      }
      options = o.merge(options.to_h)

      DoorMat.configuration.logger.send(options[:log_level] , options[:log_message])

      sign_out

      redirect_to options[:redirect_to] || config_url_redirect(:lockdown_default_redirect_url)
    end

    def handle_unverified_request
      super
    rescue ActionController::InvalidAuthenticityToken => e
      raise e
    ensure
      lockdown(log_level: :warn, log_message: 'WARN: handle_unverified_request')
    end

    def require_valid_session
      unless DoorMat::Session.current_session.valid?
        DoorMat::Session.from(cookies, request)
      else
        DoorMat.configuration.logger.error "ERROR: are you calling require_valid_session more than once?"
      end
      unless DoorMat::Session.current_session.valid?
        set_session_redirect_to

        redirect_to door_mat.sign_in_url
      end
    end

    def require_confirmed_email
      unless DoorMat::Session.current_session.valid? && (DoorMat::Session.current_session.email.confirmed? || DoorMat::Session.current_session.email.primary?)
        redirect_to door_mat.email_confirmation_required_url
      end
    end

    # To assign a custom amount of delay for a specific filter,
    # use as follow for a delay of 1 minute:
    # before_filter -> {require_password_reconfirm(1)}
    def require_password_reconfirm(minutes_old=nil)
      minutes_old ||= DoorMat.configuration.password_reconfirm_delay

      if DoorMat::Session.current_session.invalid? || DoorMat::Session.current_session.is_older_than(minutes_old)
        set_session_redirect_to
        redirect_to door_mat.reconfirm_password_url
      end
    end

    def protected_by_password_less_session(pls_symbols)
      pls_symbols = Array(pls_symbols)
      redirect_url = send("#{pls_symbols.first}_url".to_sym)

      if DoorMat::AccessToken.is_cookie_present? cookies
        DoorMat::AccessToken.validate_from_cookie(cookies, request)
        if DoorMat::AccessToken.current_access_token.valid? && pls_symbols.include?(DoorMat::AccessToken.current_access_token.token_for.to_sym)
          return if DoorMat::AccessToken.current_access_token.used? || DoorMat::AccessToken.current_access_token.multiple_use?
        end
        DoorMat::AccessToken.destroy_if_linked_to(cookies)
      end

      set_session_redirect_to
      redirect_to redirect_url
    end

    def update_session_last_activity_time

      if DoorMat::Session.current_session.valid?
        DoorMat::Session.current_session.updated_at = DateTime.current
        DoorMat::Session.current_session.save
      end

      if DoorMat::AccessToken.current_access_token.valid?
        DoorMat::AccessToken.current_access_token.updated_at = DateTime.current
        DoorMat::AccessToken.current_access_token.save
      end

    end

    def main_app_root_url
      [:main_app, :root_url].inject(self) { |lhs, rhs| lhs.send(rhs) }
    end

    def config_url_redirect(url_token)
      config_url = DoorMat.configuration.send(url_token)
      config_url.inject(self) { |lhs, rhs| lhs.send(rhs) } || main_app_root_url
    end

    private

    def set_session_redirect_to
      if request.get? && DoorMat.configuration.allow_redirect_to_requested_url
        session[:redirect_to] = request.url
      else
        session.delete(:redirect_to)
      end
    end

  end
end
