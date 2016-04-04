module DoorMat
  module Process
    class ActorSignUp

      def self.with(address, password, request, cookies, controller)
        # Destroy any session linked to existing cookies before
        # replacing it by a new session
        DoorMat::Session.destroy_if_linked_to(cookies)

        # Sign up with the credentials of
        # an existing account fails
        return false if DoorMat::Actor.authenticate_with(address, password)

        actor = DoorMat::Actor.create_with(password)
        return false if actor.blank?

        email = DoorMat::Email.for(address)
        email.status = :not_available if DoorMat::Email.count_matching(address) >= DoorMat::configuration.plausible_deniability_count
        actor.current_email = email
        DoorMat::Session.for(actor, password, request)
        return false unless DoorMat::Session.current_session.valid?

        actor.sessions << DoorMat::Session.current_session
        actor.emails << email

        # setup public key pairs
        actor.setup_public_key_pairs(DoorMat::Session.current_session)

        return false unless actor.save

        DoorMat::Session.current_session.set_up(cookies)
        DoorMat::ActivityConfirmEmail.for(email, controller)
        DoorMat::ActivityDownloadRecoveryKey.for(actor)
        true
      end

    end
  end
end
