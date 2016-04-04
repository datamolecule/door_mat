module DoorMat
  class ActivityResetPassword < Activity

    belongs_to :email, :class_name => "DoorMat::Email", :foreign_key => :notifier_id

    def self.for(email, controller)
      # BFP: prevent email flooding
      return nil unless self.where( actor: email.actor ).where(["created_at > ?", DoorMat.configuration.forgot_password_link_request_delay_minutes.minutes.ago]).blank?

      token = SecureRandom.uuid

      activity = self.new
      activity.actor = email.actor
      activity.email = email
      activity.link_hash = self.hash_token(token)
      activity.started!

      activity.send_email_with(token, controller)
      activity
    end

    def self.with(token, emails)

      self.where(type: "DoorMat::ActivityResetPassword", link_hash: self.hash_token(token)).started.each do |activity|
        if activity.created_at < DoorMat.configuration.forgot_password_link_expiration_delay_minutes.minutes.ago
          activity.failed!
        else
          return activity if emails.include? activity.email
        end
      end

      nil
    end

    def send_email_with(token, controller)
      parameters = {
          url: controller.send(:choose_new_password_url, token: token, email: self.email.to_urlsafe_encoded, protocol: DoorMat::UrlProtocol.url_protocol),
          address: self.email.address
      }
      DoorMat::ActivityMailer.reset_password(parameters).deliver_now
    rescue Exception => e
      DoorMat.configuration.logger.error "ERROR: Failed to deliver reset password email for actor #{self.actor.id} to #{self.email.address} w #{parameters[:url]} - #{e}"
      raise e
    end

  end
end
