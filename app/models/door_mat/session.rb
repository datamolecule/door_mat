module DoorMat
  class Session < ActiveRecord::Base

    belongs_to :actor
    belongs_to :email

    attr_accessor :token

    validate :initialization_performed?

    enum rating: [:public_computer, :private_computer, :remember_me]

    def initialization_performed?
      if @symmetric_actor_key.blank? || @symmetric_actor_key.first.blank? || @session_key.blank? || @token.blank? || self.hashed_token.blank?
        errors.add(:base, I18n.t("door_mat.session.initialization_failure"))
      end
    end

    # The current_session is never nil but it might not be valid
    # Check with DoorMat::Session.current_session.valid?
    def self.current_session
      RequestStore.store[:current_session] ||= self.new
    end

    # destroy existing valid session if any at sign_in and sign_up time
    # or when expired
    # to prevent unreferenced sessions from accumulating in the store
    def self.clear_current_session
      session = current_session
      RequestStore.store[:current_session] = nil

      session.destroy if session.persisted?

      nil
    end

    def self.for(actor, password, request)
      clear_current_session

      return nil if password.blank? || actor.key_salt.blank?

      session = self.new
      session.ip = request.remote_ip
      session.agent = request.user_agent

      RequestStore.store[:current_session] = session.initialize_with(actor, password)
    end

    def initialize_with(actor, password)
      reset
      self.email = actor.current_email

      re_key_with(actor, password)

      self
    rescue Exception => e
      reset
      DoorMat.configuration.logger.error "ERROR: Failed to initialize session with password for actor #{actor.id} - #{e}"

      nil
    end

    def re_key_with(actor, password)
      @symmetric_actor_key << DoorMat::Crypto::PasswordHash.pbkdf2_hash(password, actor.key_salt)

      encrypt_actor_key(actor, @symmetric_actor_key.last)
      set_new_token

      self.password_authenticated_at = DateTime.current

      self
    end

    def session_for_actor_loaded?(actor)
      actor.nil? || (self.actor == actor) || (sub_sessions.has_key? actor.id)
    end

    def self.new_sub_session_for_actor(actor, password)
      session = self.new
      session.initialize_with(actor, password)
      session.actor = actor

      session
    end

    def append_sub_session(session)
      unless DoorMat::Session.current_session == self
        DoorMat.configuration.logger.error "ERROR: append_sub_session must only be called on DoorMat::Session.current_session"
        return false
      end

      unless session.valid?
        DoorMat.configuration.logger.error "ERROR: append_sub_session was given an invalid session"
        return false
      end

      actor_id = session.actor.id
      if sub_sessions.has_key? actor_id
        DoorMat.configuration.logger.warn "WARN: sub_session #{actor_id} already present; updating."
      end
      sub_sessions[actor_id] = session

      return true
    end

    def memberships_for(actor)
      current_session_ids = sub_sessions.keys
      current_session_ids.push(self.actor_id) unless self.actor_id.nil?

      DoorMat::Membership.where("member_of_id = :member_of and member_id in (:ids)",
                                :member_of => actor.id,
                                :ids => current_session_ids).select {|m| !m.readonly?}
    end

    def autoload_sesion_for(actor)
      return if session_for_actor_loaded?(actor)

      memberships = memberships_for(actor)
      unless memberships.empty?
        membership = memberships.first
        session = DoorMat::Session.new_sub_session_for_actor(membership.member_of, membership.key)
        append_sub_session(session)
      end
    end

    def self.from(cookies, request)
      clear_current_session
      session_guid = cookies.encrypted[:session_guid].to_s.strip
      session_key = cookies.encrypted[:session_key].to_s.strip

      return nil if session_guid.blank? || session_key.blank?
      return nil if DoorMat::Regex.session_guid.match(session_guid).blank?
      session = self.find_by(hashed_token: DoorMat::Crypto::FastHash.sha256(session_guid) ) || self.new
      session.token = session_guid
      if session.actor.nil?
        session.destroy!
        return nil
      end

      case
        when session.remember_me?
          if session.created_at < DoorMat.configuration.remember_me_max_day_count.days.ago
            session.destroy!
            return nil
          end
          if session.updated_at < DoorMat.configuration.private_computer_access_session_timeout.minutes.ago
            session_key = session.renew_session_key_and_token(session_key, cookies)
          end
        when session.private_computer?
          if session.updated_at < DoorMat.configuration.private_computer_access_session_timeout.minutes.ago
            session.destroy!
            return nil
          end
        else
          if session.updated_at < DoorMat.configuration.public_computer_access_session_timeout.minutes.ago
            session.destroy!
            return nil
          end
      end

      session.ip = request.remote_ip
      session.agent = request.user_agent # Check for major change in user_agent in case of strict session policy
      session.updated_at = DateTime.current

      RequestStore.store[:current_session] = session
      if session.unlock_with(session_key)
        session.save
      else
        clear_current_session
      end
    end

    def renew_session_key_and_token(old_session_key, cookies)

      if unlock_with(old_session_key)
        encrypt_actor_key(self.actor, @symmetric_actor_key.last)
        set_new_token

        set_up(cookies)
      end

      @session_key
    end

    def unlock_with(session_key)
      @symmetric_actor_key = [DoorMat::Crypto::SymmetricStore.decrypt(
          self.encrypted_symmetric_actor_key,
          self.actor.system_decrypt(session_key)
      )]
      @session_key = session_key

      true
    rescue Exception => e
      reset
      DoorMat.configuration.logger.error "ERROR: Failed to unlock session with session_key for actor #{self.actor.id} - #{e}"
      false
    end

    def self.destroy_if_linked_to(cookies)
      session_guid = cookies.encrypted[:session_guid].to_s.strip
      clean_up(cookies)

      return false if DoorMat::Regex.session_guid.match(session_guid).blank?
      session = self.find_by(hashed_token: DoorMat::Crypto::FastHash.sha256(session_guid) ) || self.new
      return false unless session.persisted?
      session.destroy!

      true
    end

    def set_up(cookies)
      options = {
          secure: DoorMat.configuration.transmit_cookies_only_over_https,
          httponly: true
      }
      options.merge!({ expires: DoorMat.configuration.remember_me_max_day_count.days.since(self.created_at) }) unless self.public_computer?

      cookies.encrypted[:session_guid] = options.merge({value: self.token})
      cookies.encrypted[:session_key] = options.merge({value: @session_key})

      nil
    end

    def self.clean_up(cookies)
      cookies.delete(:session_guid)
      cookies.delete(:session_key)

      nil
    end

    def is_older_than(minutes_old)
      self.password_authenticated_at < minutes_old.minutes.ago
    end

    def with_session_for_actor(actor)
      if self.valid? && (actor.nil? || self.actor_id.nil? || self.actor == actor)
        yield(self)
      elsif !actor.nil? && (sub_sessions.has_key? actor.id)
        yield(sub_sessions[actor.id])
      end
    end

    def encrypt(message)
      DoorMat::Crypto::SymmetricStore.encrypt(message, @symmetric_actor_key.last)[:ciphertext]
    end

    def decrypt(ciphertext)
      DoorMat::Crypto::SymmetricStore.decrypt(ciphertext, @symmetric_actor_key.first)
    rescue OpenSSL::Cipher::CipherError => e
      DoorMat.configuration.logger.warn "WARN: Failed to decrypt for actor #{self.actor.id} - #{e}"
      nil
    end

    def package_recovery_key
      h = DoorMat::Crypto::SymmetricStore.encrypt(@symmetric_actor_key.last)
      self.actor.recovery_key = h[:ciphertext]
      self.actor.save!
      self.actor.system_encrypt(h[:key])
    end

    def recovery_key_restore(actor, recovery_key)
      self.actor = actor
      key = self.actor.system_decrypt(recovery_key)
      @symmetric_actor_key = [DoorMat::Crypto::SymmetricStore.decrypt(self.actor.recovery_key, key)]
      true
    rescue OpenSSL::Cipher::CipherError => e
      DoorMat.configuration.logger.warn "WARN: Failed recovery_key_restore for actor #{self.actor.id} - #{e}"
      false
    end

    def reconfirm_password(password)
      if self.actor.authenticate(password)
        self.password_authenticated_at = DateTime.current
        self.save!
        true
      else
        false
      end
    end

    private

    def reset
      # This key must never be stored or shared in clear outside this object
      @symmetric_actor_key = []
      # This token must never be stored in clear on the system side
      @token = ''
      # This random key is encrypted with the actor system_key and used to decrypt the session symmetric_actor key; see unlock_with(session_key)
      @session_key = ''
      # Sub sessions grant access to data associated with additional actors
      @sub_sessions = {}

      nil
    end

    def sub_sessions
      @sub_sessions ||= {}
    end

    def encrypt_actor_key(actor, actor_key)
      symmetric_store = DoorMat::Crypto::SymmetricStore.encrypt(actor_key)
      self.encrypted_symmetric_actor_key = symmetric_store[:ciphertext]
      @session_key = actor.system_encrypt(symmetric_store[:key])

      nil
    end

    def set_new_token
      @token = SecureRandom.uuid

      self.hashed_token = DoorMat::Crypto::FastHash.sha256(@token)
    end

  end
end
