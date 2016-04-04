module DoorMat
  class Activity < ActiveRecord::Base

    belongs_to :actor
    belongs_to :notifier, :polymorphic => true

    enum status: [:pending, :started, :done, :failed]

    def self.hash_token(token)
      DoorMat::Crypto::FastHash.sha256(token)
    end

  end
end
