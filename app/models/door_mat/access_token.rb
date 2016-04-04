module DoorMat
  class AccessToken < ActiveRecord::Base

    include DoorMat::AttrSymmetricStore

    belongs_to :actor, class_name: 'DoorMat::Actor'

    attr_symmetric_store :name, :identifier, :data

    enum token_for: (k = DoorMat.configuration.password_less_sessions.keys; k.delete(:password_less_defaults); k)
    enum status: [:single_use, :multiple_use, :used]
    enum rating: [:public_computer, :private_computer, :remember_me]

    attr_accessor :token, :is_public, :remember_me

    after_initialize :init

    def init
      self.is_public = true if self.is_public.nil?
      self.remember_me = false if self.remember_me.nil?
    end

    validate :initialization_performed?

    def initialization_performed?
      if self.actor.blank? || self.hashed_token.blank?
        errors.add(:base, "Access token invalid")
      end
    end

    def self.current_access_token
      RequestStore.store[:current_access_token] ||= self.new
    end

    def self.clear_current_access_token
      access_token = current_access_token
      RequestStore.store[:current_access_token] = nil

      access_token.destroy if access_token.persisted?
      nil
    end

    def self.token_for_is_valid(token_for_symbol)
      DoorMat.configuration.password_less_sessions.has_key? token_for_symbol
    end

    def self.new_with_token_for(token_for, request)
      access_token = self.new
      token_for_symbol = token_for.to_s.strip.to_sym
      if token_for_is_valid(token_for_symbol)
        access_token.token_for = self.token_fors[token_for_symbol]
      else
        DoorMat.configuration.logger.warn "WARN: #{request.remote_ip} Attempted to use inexistent token_for #{token_for}"
        access_token.errors[:base] << I18n.t("door_mat.password_less_session.create_failed")
      end
      access_token
    end

    def self.create_from_params(token_for, identifier, confirm_identifier, name, is_public, remember_me, request)
      clear_current_access_token
      is_public = '1' == is_public.to_s
      remember_me = '1' == remember_me.to_s

      access_token = new_with_token_for(token_for, request)
      return access_token unless access_token.errors.blank?

      access_token.identifier = identifier
      access_token.name = name || 'access token'

      if access_token.identifier.blank?
        access_token.errors[:identifier] << I18n.t("door_mat.password_less_session.blank_identifier")
        return access_token
      end

      if access_token.session_parameters[:challenge].include? :email
        if DoorMat::Regex.simple_email.match(access_token.identifier).blank?
          access_token.errors[:identifier] << I18n.t("door_mat.password_less_session.expect_email_identifier")
          return access_token
        end
      end

      unless identifier == confirm_identifier
        access_token.errors[:identifier] << I18n.t("door_mat.password_less_session.identifier_error")
        return access_token
      end

      unless [:single_use, :multiple_use].include? access_token.session_parameters[:status]
        DoorMat.configuration.logger.error "ERROR: #{request.remote_ip} Status must be either :single_use or :multiple_use check your configuration - found #{access_token.session_parameters[:status]}"
        access_token.errors[:base] << I18n.t("door_mat.password_less_session.create_failed")
        return access_token
      end
      access_token.status = access_token.session_parameters[:status]

      unless access_token.load_sub_session
        access_token.errors[:base] << I18n.t("door_mat.password_less_session.actor_missing")
        return access_token
      end

      access_token.generate_new_token

      if is_public
        access_token.public_computer!
      else
        access_token.private_computer!
      end

      # User asked to be remembered
      if DoorMat.configuration.allow_remember_me_feature && remember_me
        access_token.remember_me! unless (
        DoorMat.configuration.remember_me_require_private_computer_confirmation &&
            access_token.public_computer?
        )
      end

      access_token
    end

    def form_submit_path(controller)
      session_parameters.fetch(:form_submit_path).inject(controller) { |lhs, rhs| lhs.send(rhs) }
    end

    def generate_new_token
      @token = SecureRandom.uuid
      self.hashed_token = DoorMat::Crypto::FastHash.sha256(@token)
    end

    def session_parameters
      @session_params ||= DoorMat.configuration.password_less_sessions[self.token_for.to_sym]
    end

    def default_parameters
      @default_parameters ||= DoorMat.configuration.password_less_sessions[:password_less_defaults]
    end

    def default_failure_url
      session_parameters.fetch(:default_failure_url, generic_redirect_url)
    end

    def default_success_url
      session_parameters.fetch(:default_success_url, generic_redirect_url)
    end

    def generic_redirect_url
      default_parameters.fetch(:generic_redirect_url, [:main_app, :root_url])
    end

    def load_actor_for_session
      self.actor ||= DoorMat::Actor.authenticate_with(self.session_parameters[:actor][:email], self.session_parameters[:actor][:password])
      if self.actor.nil?
        DoorMat.configuration.logger.error "ERROR: Could not authenticate actor #{self.session_parameters[:actor][:email]} is it in your database?"
        return false
      end
      true
    end

    def load_sub_session
      return false unless load_actor_for_session

      unless DoorMat::Session.current_session.session_for_actor_loaded? self.actor
        sub_session = DoorMat::Session.new_sub_session_for_actor(self.actor, self.session_parameters[:actor][:password])
        DoorMat::Session.current_session.append_sub_session(sub_session)
      end
      true
    end

    def self.swap_token!(cookies, valid_current_session_tokens, new_session_token, force_new_token_generation = false)
      access_token = current_access_token

      # Our current access token is in order
      return unless access_token.valid?

      valid_transitions = access_token.session_parameters.fetch(:transitions, [])
      # The current access token is for one of the valid_current_session_tokens
      return unless Array(valid_current_session_tokens).include? access_token.token_for.to_sym
      # The transition is valid
      return unless valid_transitions.include? new_session_token

      blank_new_session_access_token = self.new
      blank_new_session_access_token.token_for = self.token_fors[new_session_token]
      return unless blank_new_session_access_token.load_actor_for_session
      issue_new_token = force_new_token_generation || access_token.multiple_use? || (access_token.actor_id != blank_new_session_access_token.actor_id)

      if issue_new_token
        RequestStore.store[:current_access_token] = blank_new_session_access_token

        if access_token.used?
          access_token.destroy!
        end

        blank_new_session_access_token.renew_token(cookies)
        blank_new_session_access_token.name = access_token.name
        blank_new_session_access_token.identifier = access_token.identifier
        blank_new_session_access_token.data = access_token.data
        blank_new_session_access_token.reference_id = access_token.reference_id
        blank_new_session_access_token.used!
      else
        # For a single user ticket, just update the token_for value
        if access_token.used?
          access_token.token_for = self.token_fors[new_session_token]
          access_token.save!
        end
      end
    end

    def self.is_cookie_present?(cookies)
      !cookies.encrypted[:token].blank?
    end

    def self.load_token(token, request, verbose=true)
      token = token.to_s.strip
      if DoorMat::Regex.session_guid.match(token).blank?
        DoorMat.configuration.logger.warn "WARN: #{request.remote_ip} Attempted to use token with invalid format #{token}" if verbose
        return nil
      end

      access_token = self.find_by_hashed_token DoorMat::Crypto::FastHash.sha256(token)
      if access_token.blank?
        DoorMat.configuration.logger.warn "WARN: #{request.remote_ip} Attempted to use inexistent token #{token}" if verbose
        return nil
      end

      return nil unless access_token.load_sub_session

      # Reload the token using find now that the sub_session is loaded
      # to allow the encrypted field to be decrypted
      # the request hits the cache so there is no additional round trip to the DB
      access_token = self.find(access_token.id)
      access_token.token = token
      access_token
    end

    def renew_token(cookies)
      generate_new_token

      set_up(cookies)
    end

    def self.validate_token(token, cookies, request)
      access_token = load_token(token, request)

      access_token = case
        when access_token.blank?
          nil
        # For an unused token, check if the link has expired against access_token.session_parameters[:expiration_delay].ago
        when access_token.single_use?, access_token.multiple_use?
          if access_token.created_at < access_token.session_parameters[:expiration_delay].ago
            DoorMat.configuration.logger.info "INFO: #{request.remote_ip} Attempted to use expired token #{token}"
            access_token.destroy!
            nil
          else
            access_token
          end
        # otherwise, for an ongoing session, use public / private / remember_me expiration delay
        when access_token.public_computer?
          if access_token.updated_at < DoorMat.configuration.public_computer_access_session_timeout.minutes.ago
            access_token.destroy!
            nil
          else
            access_token
          end
        when access_token.private_computer?
          if access_token.updated_at < DoorMat.configuration.private_computer_access_session_timeout.minutes.ago
            access_token.destroy!
            nil
          else
            access_token
          end
        when access_token.remember_me?
          if access_token.created_at < DoorMat.configuration.remember_me_max_day_count.days.ago
            access_token.destroy!
            nil
          else
            if access_token.updated_at < DoorMat.configuration.private_computer_access_session_timeout.minutes.ago
              access_token.renew_token(cookies)
              access_token.save
            end
            access_token
          end
      end

      access_token
    end

    def self.validate_from_cookie(cookies, request)
      token = cookies.encrypted[:token]
      RequestStore.store[:current_access_token] = validate_token(token, cookies, request)
      clean_up(cookies) if RequestStore.store[:current_access_token].nil?
    end

    def self.destroy_if_linked_to(cookies)
      token = cookies.encrypted[:token] || ''
      clean_up(cookies)

      access_token = load_token(token, nil, false)
      return false if access_token.blank?

      access_token.destroy! unless access_token.multiple_use?
      true
    end

    def set_up(cookies)
      options = {
          secure: DoorMat.configuration.transmit_cookies_only_over_https,
          httponly: true
      }
      options.merge!({ expires: DoorMat.configuration.remember_me_max_day_count.days.since(self.created_at) }) unless self.public_computer?
      cookies.encrypted[:token] = options.merge({value: self.token})
    end

    def self.clean_up(cookies)
      cookies.delete(:token)
    end

  end
end
