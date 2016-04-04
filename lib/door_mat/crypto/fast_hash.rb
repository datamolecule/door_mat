require 'openssl'

module DoorMat
  module Crypto
    module FastHash
      
      def sha256(data)
        sha256 = OpenSSL::Digest::SHA256.new
        Base64.urlsafe_encode64(
          sha256.digest(data.to_str)
        )
      end
      module_function :sha256

    end
  end
end
