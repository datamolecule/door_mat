module DoorMat
  class Email < ActiveRecord::Base

    include DoorMat::AttrSymmetricStore

    belongs_to :actor
    has_many :sessions, :dependent => :destroy

    validates_presence_of :address_hash, :address
    validates_format_of :address, with: DoorMat::Regex.simple_email

    attr_symmetric_store :address

    enum status: [:not_confirmed, :confirmed, :primary, :not_available]

    def self.address_hash(address)
      DoorMat::Crypto::FastHash.sha256(address.to_str)
    end

    def self.decode_urlsafe(encoded_address)
      Base64.urlsafe_decode64(encoded_address.to_str)
    rescue ArgumentError
      return encoded_address.to_str
    end

    def self.address_hash_from_encoded_address(encoded_address)
      self.address_hash(self.decode_urlsafe(encoded_address))
    end

    def self.matching(address)
      address_hash = self.address_hash(address.to_str)
      self.where(address_hash: address_hash)
    end

    def self.confirmed_matching(address)
      address_hash = self.address_hash(address.to_str)
      self.where(address_hash: address_hash).where('status = :confirmed or status = :primary', self.statuses)
    end

    def self.count_matching(address)
      address_hash = self.address_hash(address.to_str)
      self.where(address_hash: address_hash).count
    end

    def self.for(address)
      e = self.new
      e.address_hash = self.address_hash(address.to_str)
      e.address = address.to_str
      e.status = :not_confirmed
      e
    end

    def to_urlsafe_encoded
      Base64.urlsafe_encode64(self.address)
    end

  end
end
