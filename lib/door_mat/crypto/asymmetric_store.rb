require 'openssl'

module DoorMat
  module Crypto
    module AsymmetricStore

      def encrypt(plaintext, public_key)
        raise ArgumentError, 'Plaintext exceeds maximum length of 245 bytes' if plaintext.to_str.bytesize > 245
        Base64.strict_encode64(public_key.public_encrypt(plaintext.to_str))
      end
      module_function :encrypt

      def decrypt(ciphertext, private_key)
        private_key.private_decrypt(Base64.strict_decode64(ciphertext.to_str))
      end
      module_function :decrypt

      def generate_pem_encrypted_pkey_pair_and_key
        pkey = OpenSSL::PKey::RSA.generate(2048)
        c = cipher()
        c.encrypt
        c.random_iv
        key = c.random_key
        pem_encrypted_pkey = ''

        begin

          pem_encrypted_pkey = pkey.to_pem(c, key)

        rescue OpenSSL::PKey::RSAError => e
          DoorMat.configuration.logger.error "ERROR: spurious error - #{e} for key _#{key}_"
          key = c.random_key
          retry
        end

        {
            key: Base64.strict_encode64(key),
            pem_encrypted_pkey: pem_encrypted_pkey
        }
      end
      module_function :generate_pem_encrypted_pkey_pair_and_key

      def private_key_from_pem_encrypted_pkey_pair(pem_encrypted_pkey, key)
        OpenSSL::PKey::RSA.new(pem_encrypted_pkey.to_str, decode_key(key.to_str))
      end
      module_function :private_key_from_pem_encrypted_pkey_pair

      def public_key_from_pem_encrypted_pkey_pair(pem_encrypted_pkey, key)
        OpenSSL::PKey::RSA.new(pem_encrypted_pkey.to_str, decode_key(key.to_str)).public_key
      end
      module_function :public_key_from_pem_encrypted_pkey_pair

      def pem_public_key_from_pem_encrypted_pkey_pair(pem_encrypted_pkey, key)
        public_key_from_pem_encrypted_pkey_pair(pem_encrypted_pkey.to_str, key.to_str).to_pem
      end
      module_function :pem_public_key_from_pem_encrypted_pkey_pair

      def public_key_from_pem_public_key(pem_public_key)
        OpenSSL::PKey::RSA.new(pem_public_key.to_str).public_key
      end
      module_function :public_key_from_pem_public_key

      def cipher
        OpenSSL::Cipher.new('DES-EDE3-CBC')
      end
      module_function :cipher

      def decode_key(key)
        Base64.strict_decode64(key.to_str).tap do |decoded_key|
          raise ArgumentError, "Key must be exactly 24 bytes in length" if decoded_key.bytesize != 24
        end
      end
      module_function :decode_key

    end
  end
end
