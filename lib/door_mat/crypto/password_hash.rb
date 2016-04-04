require 'openssl'
require 'bcrypt'

module DoorMat
  module Crypto
    module PasswordHash

      def pbkdf2_salt(salt_length=nil, password_length=nil, iterations=nil)
        salt_length ||= DoorMat.configuration.crypto_pbkdf2_salt_length
        password_length ||= DoorMat.configuration.crypto_pbkdf2_password_length
        iterations ||= DoorMat.configuration.crypto_pbkdf2_iterations

        [password_length, iterations, OpenSSL::Random.random_bytes(salt_length)].map { |s| Base64.strict_encode64(s.to_s)}.join('--')
      end
      module_function :pbkdf2_salt

      def pbkdf2_hash(password, salt)
        length, iterations, salt = salt.to_str.split('--').map { |s| Base64.strict_decode64(s) }
        Base64.strict_encode64(
            OpenSSL::PKCS5.pbkdf2_hmac_sha1(password.to_str, salt, Integer(iterations), Integer(length))
        )
      end
      module_function :pbkdf2_hash

      def bcrypt_salt(cost=nil)
        cost ||= DoorMat.configuration.crypto_bcrypt_cost
        BCrypt::Engine.generate_salt(Integer(cost))
      end
      module_function :bcrypt_salt

      def bcrypt_hash(password, salt=nil)
        salt ||= bcrypt_salt
        BCrypt::Engine.hash_secret(password.to_str, salt.to_str)
      end
      module_function :bcrypt_hash

    end
  end
end
