module DoorMat
  module Regex

    def self.simple_email
      # http://tools.ietf.org/html/rfc3696#section-3
      # min 1 char local part and min 2 char domain part
      # max 64 char local part and max 255 char domain part
      # first and last char can not be blank
      /\A\S.{0,63}@.{1,254}\S\z/
    end

    def self.session_guid
      /\A[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\z/
    end

  end
end
