module DoorMat
  class PasswordLessSessionController < DoorMat::ApplicationController
    skip_before_action :require_valid_session, :only => [:new, :create, :access_token, :access_token_post]

    def new
      @access_token = DoorMat::AccessToken.new_with_token_for(params[:token_for], request)
    end

    def create
      DoorMat::AccessToken.destroy_if_linked_to(cookies)

      @access_token = DoorMat::AccessToken.create_from_params(params[:token_for],
                                                              access_token_params[:identifier],
                                                              access_token_params[:confirm_identifier],
                                                              access_token_params[:name],
                                                              access_token_params[:is_public],
                                                              access_token_params[:remember_me],
                                                              request)
      if @access_token.errors.size > 0
        render :new
      else
        @access_token.save!
        deliver_token(@access_token)
        redirect_to door_mat.access_token_token_for_token_url(@access_token.token_for)
      end
    end

    def access_token
      token_for = params[:token_for]
      token = params[:token]

      if token.blank?
        @access_token = DoorMat::AccessToken.new_with_token_for(params[:token_for], request)
        render :access_token
      else
        process_request(token_for, token)
      end
    end

    def access_token_post
      token_for = access_token_params[:token_for]
      token = access_token_params[:identifier]
      process_request(token_for, token)
    end

    private

    def access_token_params
      params.require(:access_token).permit(:identifier, :confirm_identifier, :token_for, :name, :is_public, :remember_me)
    end

    def process_request(token_for, token)
      if process_token_request(token_for, token)
        redirect_to session.delete(:redirect_to) || @access_token.default_success_url.inject(self) { |lhs, rhs| lhs.send(rhs) }
      else
        render_failed_token_request(token)
      end

    end

    def render_failed_token_request(token)
      if DoorMat::Regex.session_guid.match(token).blank?
        flash.now[:alert] = "The format of your access token is invalid. Please verify there are no missing or extra characters."
      else
        flash.now[:alert] = "Something looks wrong with your access token. Please request a new one."
      end
      render :access_token
    end

    def process_token_request(token_for, token, klass = DoorMat::AccessToken)
      klass.destroy_if_linked_to(cookies)
      @access_token = nil

      token_for_symbol = token_for.to_s.strip.to_sym
      return false unless klass.token_for_is_valid(token_for_symbol)

      @access_token = klass.validate_token(token, cookies, request)
      unless @access_token.blank?
        # This is a request so the token must have a status of :single_use or :multiple_use
        if (@access_token.single_use? || @access_token.multiple_use?)

          # mark single use tickets as used so they can't be reused
          if @access_token.single_use?
            @access_token.used!
          end

          validate = @access_token.session_parameters[:validate]
          is_valid = true
          is_valid = validate.call(@access_token.identifier) if validate

          if is_valid
            @access_token.set_up(cookies)
            return true
          else
            DoorMat.configuration.logger.warn "WARN: #{request.remote_ip} Identifier #{@access_token.identifier} did not satisfy validation"
            @access_token.destroy!
          end

        end
      end

      @access_token = klass.new_with_token_for(token_for_symbol, request)
      return false
    end

    def deliver_token(access_token)
      parameters = {
          url_full: access_token_token_for_token_url(token_for: access_token.token_for, token: access_token.token, protocol: DoorMat::UrlProtocol.url_protocol),
          url_short: access_token_token_for_token_url(token_for: access_token.token_for, protocol: DoorMat::UrlProtocol.url_protocol),
          token: access_token.token,
          address: access_token.identifier,
          subject: "Your access token"
      }
      DoorMat::PasswordLessSessionMailer.send_token(parameters).deliver_now
    rescue Exception => e
      DoorMat.configuration.logger.error "ERROR: Failed to deliver access token to #{parameters[:address]} w #{parameters[:token]} - #{e}"
      raise e
    end

  end
end
