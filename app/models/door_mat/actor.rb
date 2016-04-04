module DoorMat
  class Actor < ActiveRecord::Base

    has_many :emails, :dependent => :destroy
    has_many :sessions, :dependent => :destroy
    has_many :activities, :dependent => :destroy
    has_many :access_tokens, :dependent => :destroy

    has_many :memberships,
             :inverse_of => :member,
             :foreign_key => :member_id,
             :class_name => 'DoorMat::Membership',
             :dependent => :destroy
    has_many :anonymous_actors,
             :through => :memberships,
             :source => :member_of

    has_many :members,
             :inverse_of => :member_of,
             :foreign_key => :member_of_id,
             :class_name => 'DoorMat::Membership',
             :dependent => :destroy
    has_many :member_actors,
             :through => :members,
             :source => :member

    attr_accessor :current_email

    validates_presence_of :key_salt, :password_salt, :password_hash, :system_key

    def self.create_with(password)
      actor = self.new

      actor.re_key_with(password)

      actor.system_key = DoorMat::Crypto::SymmetricStore.random_key

      actor
    end

    def re_key_with(password)
      self.key_salt = DoorMat::Crypto::PasswordHash.pbkdf2_salt

      self.password_salt = DoorMat::Crypto::PasswordHash.bcrypt_salt
      self.password_hash = DoorMat::Crypto::PasswordHash.bcrypt_hash(password, self.password_salt)
    end

    def self.authenticate_with(address, password)
      actor = nil
      matching_emails = DoorMat::Email.matching(address)

      # As with a secure_compare, spend constant time
      # testing the password against all the accounts, all the time, even if
      # the first account is matching
      matching_emails.each do |e|
        if e.actor.authenticate(password)
          actor = e.actor
          actor.current_email = e
        end
      end

      actor
    end

    def confirm_email_activities
      activities.started.where(type: "DoorMat::ActivityConfirmEmail")
    end

    def download_recovery_key_activities
      activities.started.where(type: "DoorMat::ActivityDownloadRecoveryKey")
    end

    def can_add_email?(email)
      if emails.count >= DoorMat::configuration.max_email_count_per_actor
        email.errors[:base] << I18n.t("door_mat.actor.max_email_count_per_actor_reached")
        return false
      end

      if emails.where(:address_hash => email.address_hash).count > 0
        email.errors[:base] << I18n.t("door_mat.actor.email_already_associated")
        return false
      end

      true
    end

    def has_primary_email?
      emails.map {|e| e.primary?}.inject(false, :|)
    end

    def email_from_urlsafe_encoded(encoded_address)
      emails.where(:address_hash => DoorMat::Email.address_hash_from_encoded_address(encoded_address)).first
    end

    def system_encrypt(message)
      DoorMat::Crypto::SymmetricStore.encrypt(message, self.system_key)[:ciphertext]
    end

    def system_decrypt(ciphertext)
      DoorMat::Crypto::SymmetricStore.decrypt(ciphertext, self.system_key)
    end

    def authenticate(password)
      DoorMat::Crypto::secure_compare(
          self.password_hash,
          DoorMat::Crypto::PasswordHash.bcrypt_hash(password, self.password_salt)
      )
    end

    def setup_public_key_pairs(session)
      pem_encrypted_pkey_pair_and_key = DoorMat::Crypto::AsymmetricStore.generate_pem_encrypted_pkey_pair_and_key
      self.encrypted_pem_key = session.encrypt(pem_encrypted_pkey_pair_and_key[:key])
      self.pem_encrypted_pkey = pem_encrypted_pkey_pair_and_key[:pem_encrypted_pkey]
      self.pem_public_key = DoorMat::Crypto::AsymmetricStore.pem_public_key_from_pem_encrypted_pkey_pair(pem_encrypted_pkey_pair_and_key[:pem_encrypted_pkey], pem_encrypted_pkey_pair_and_key[:key])
    end

    def encrypt_shared_key(key)
      self_pub_key = DoorMat::Crypto::AsymmetricStore.public_key_from_pem_public_key(self.pem_public_key)
      DoorMat::Crypto::AsymmetricStore.encrypt(key, self_pub_key)
    end

    def decrypt_shared_key(key, session)
      pem_key = session.decrypt(self.encrypted_pem_key)
      private_key = DoorMat::Crypto::AsymmetricStore.private_key_from_pem_encrypted_pkey_pair(self.pem_encrypted_pkey, pem_key)
      DoorMat::Crypto::AsymmetricStore.decrypt(key, private_key)
    end

    def share_with(other, secrets, with_key=nil)
      secrets = Array(secrets)
      with_key ||= DoorMat::Crypto::SymmetricStore.random_key
      self_shared_key = self.encrypt_shared_key(with_key)
      other_shared_key = other.encrypt_shared_key(with_key)
      encrypted_secrets = DoorMat::Crypto.encrypt_shared(secrets, with_key)

      {
          key: self_shared_key,
          other_key: other_shared_key,
          secrets: encrypted_secrets
      }
    end

    def keep_only_this_session!(session)
      sessions.each do |s|
        s.destroy! unless s == session
      end
    end

  end
end
