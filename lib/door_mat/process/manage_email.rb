module DoorMat
  module Process
    class ManageEmail

      def self.add(email, actor, controller)
        return false unless email.valid?

        actor.with_lock do
          return false unless actor.can_add_email? email

          email.status = :not_available if DoorMat::Email.count_matching(email.address) > DoorMat::configuration.plausible_deniability_count

          actor.emails << email

          DoorMat::ActivityConfirmEmail.for(email, controller)
        end

        true
      end

      def self.set_primary(encoded_address, actor)
        actor.with_lock do
          email = actor.email_from_urlsafe_encoded(encoded_address)
          return false if email.blank?

          return true if email.primary?

          return false unless email.confirmed?

          actor.emails.primary.each do |e|
            e.confirmed!
          end

          email.primary!
        end

        true
      end

    end
  end
end
