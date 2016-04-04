require 'openssl'

module DoorMat
  module Crypto
    module SymmetricStore

      def encrypt(plaintext, key=nil)
        c = cipher()
        c.encrypt
        key = if key.nil?
                c.random_key
              else
                c.key = decode_key(key.to_str)
              end
        iv = c.random_iv
        plaintext_str = plaintext.to_str
        if plaintext_str.blank?
          return {
              key: Base64.strict_encode64(key),
              ciphertext: ""
          }
        end
        encrypted_string = c.update(plaintext_str) + c.final
        encoding = plaintext_str.encoding.name

        {
            key: Base64.strict_encode64(key),
            ciphertext: [encoding, c.auth_tag, iv, encrypted_string].map { |s| Base64.strict_encode64(s)}.join('--')
        }
      end
      module_function :encrypt

      def decrypt(ciphertext, key)
        return "" if ciphertext.to_str.blank?

        c = cipher()
        c.decrypt
        c.key = decode_key(key.to_str)
        encoding, auth_tag, iv, encrypted_string = ciphertext.to_str.split('--').map { |s| Base64.strict_decode64(s) }
        c.iv = iv
        c.auth_tag = auth_tag
        plaintext_str = c.update(encrypted_string) + c.final
        plaintext_str.force_encoding(encoding)
      end
      module_function :decrypt

      def cipher
        OpenSSL::Cipher.new('aes-256-gcm')
      end
      module_function :cipher

      def decode_key(key)
        Base64.strict_decode64(key.to_str).tap do |decoded_key|
          raise ArgumentError, "Key must be exactly 32 bytes in length" if decoded_key.bytesize != 32
        end
      end
      module_function :decode_key

      def random_key
        c = cipher()
        c.encrypt
        Base64.strict_encode64(c.random_key)
      end
      module_function :random_key

    end
  end
end
