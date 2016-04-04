require "securerandom"

module DoorMat
  module Crypto

    # http://groups.google.com/group/rubyonrails-security/browse_thread/thread/da57f883530352ee#
    # constant-time comparison algorithm to prevent timing attacks
    def secure_compare(lhs, rhs, constant_length=nil)
      constant_length ||= DoorMat.configuration.crypto_secure_compare_default_length
      constant_length = [constant_length.to_int, lhs.to_str.bytesize, rhs.to_str.bytesize].max
      random_padding = SecureRandom.random_bytes(constant_length)

      l = lhs.to_str.ljust(constant_length, random_padding).unpack "C#{constant_length}"
      r = rhs.to_str.ljust(constant_length, random_padding).unpack "C#{constant_length}"

      result = 0
      l.zip(r) { |a,b| result |= a ^ b }
      0 == result
    end
    module_function :secure_compare

  end
end
