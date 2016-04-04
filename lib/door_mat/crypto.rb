require 'door_mat/crypto/secure_compare'
require 'door_mat/crypto/password_hash'
require 'door_mat/crypto/symmetric_store'
require 'door_mat/crypto/asymmetric_store'
require 'door_mat/crypto/fast_hash'

module DoorMat
  module Crypto

    def self.encrypt_shared(secrets, with_key)
      Array(secrets).map do |s|
        DoorMat::Crypto::SymmetricStore.encrypt(s, with_key)[:ciphertext]
      end
    end

    def self.decrypt_shared(secrets, with_key)
      Array(secrets).map do |s|
        DoorMat::Crypto::SymmetricStore.decrypt(s, with_key)
      end
    end

    def self.current_skip_crypto_callback
      RequestStore.store[:current_skip_crypto_callback] ||= DoorMat::Crypto::SkipCallback.new
    end

    def self.skip_crypto_callback
      DoorMat::Crypto.current_skip_crypto_callback.skip!
      yield
    ensure
      DoorMat::Crypto.current_skip_crypto_callback.reset
    end

    class SkipCallback
      def initialize
        @skip = false
      end
      def skip?
        @skip
      end
      def skip!
        @skip = true
      end
      def reset
        @skip = false
      end
    end

  end
end
