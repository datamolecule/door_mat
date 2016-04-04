module DoorMat
  module Process
    class ResetPassword

      def self.for(address, controller)
        emails = DoorMat::Email.confirmed_matching(address)
        return false if emails.blank?

        # Several DoorMat::Email could match the address
        # pick the first one for now.
        # They will all be tested at reset time to apply the reset to the proper one
        email = emails.first

        # Because email was loaded without a valid session
        # the address attribute is still encrypted.
        # Temporarily update it here with the plain text.
        # The reason it is trusted is because the hash
        # of the user input matched a previously confirmed email address
        # hash already in the system.
        email.address = address

        DoorMat::ActivityResetPassword.for(email, controller)
        true
      end

      def self.with(forgot_password)
        emails = DoorMat::Email.confirmed_matching(forgot_password.email)
        return false if emails.blank?

        activity = DoorMat::ActivityResetPassword.with(forgot_password.token, emails)
        return false if activity.blank?

        return false if forgot_password.recovery_key.blank?
        recovery_key = forgot_password.recovery_key.read

        emails.each do |email|
          if DoorMat::Process::ActorPasswordChange.after_password_reset(email.actor, forgot_password.password, recovery_key)
            DoorMat::ActivityDownloadRecoveryKey.for(email.actor)
            activity.done!
            return true
          end
        end

        activity.failed!
        return false
      end

    end
  end
end
