module DoorMat
  module UrlProtocol

    def self.url_protocol
      Rails.application.config.force_ssl ? 'https' : 'http'
    end

  end
end
