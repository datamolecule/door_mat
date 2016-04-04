module DoorMat
  class ActivityConfirmEmail < Activity

    belongs_to :email, :class_name => "DoorMat::Email", :foreign_key => :notifier_id

    def self.for(email, controller)
      return unless email.not_confirmed?

      actor = email.actor

      # Fail any existing email confirmation activities for the current email
      actor.confirm_email_activities.each do |a|
        a.failed! if email == a.email
      end
      token = SecureRandom.uuid

      activity = self.new
      activity.actor = actor
      activity.email = email
      activity.link_hash = self.hash_token(token)
      activity.started!

      activity.send_email_with(token, controller)
    end

    def input_valid?(token, encoded_address)
      DoorMat::Crypto.secure_compare(
          [DoorMat::Activity.hash_token(token.to_s), DoorMat::Email.address_hash_from_encoded_address(encoded_address)].join('_'),
          [self.link_hash, self.email.address_hash].join('_')
      ) && self.email.not_confirmed?
    end

    def send_email_with(token, controller)
      parameters = {
          url: controller.send(:confirm_email_url, token: token, email: self.email.to_urlsafe_encoded, protocol: DoorMat::UrlProtocol.url_protocol),
          address: self.email.address
      }
      DoorMat::ActivityMailer.confirm_email(parameters).deliver_now
    rescue Exception => e
      DoorMat.configuration.logger.error "ERROR: Failed to deliver confirmation email for actor #{self.actor.id} to #{self.email.address} w #{parameters[:url]} - #{e}"
      raise e
    end

  end
end
