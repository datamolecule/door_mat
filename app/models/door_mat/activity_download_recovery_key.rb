module DoorMat
  class ActivityDownloadRecoveryKey < Activity

    def self.for(actor)
      # Fail any existing activities
      actor.download_recovery_key_activities.each do |a|
        a.failed!
      end

      activity = self.new
      activity.actor = actor
      activity.notifier = actor
      activity.link_hash = self.hash_token(SecureRandom.uuid)
      activity.started!
    end

    def input_valid?(token)
      DoorMat::Crypto.secure_compare(DoorMat::Activity.hash_token(token.to_s), self.link_hash)
    end

    def get_new_token
      token = SecureRandom.uuid
      self.link_hash = DoorMat::Activity.hash_token(token)
      self.save!

      token
    end

  end
end
