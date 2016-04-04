module DoorMat
  module Process
    class ActorSignIn

      def self.with(email, password, is_public, remember_me, request, cookies)
        # Destroy any session linked to existing cookies before
        # replacing it by a new session
        DoorMat::Session.destroy_if_linked_to(cookies)

        actor = DoorMat::Actor.authenticate_with(email, password)
        return false if actor.blank?

        DoorMat::Session.for(actor, password, request)
        return false unless DoorMat::Session.current_session.valid?

        if is_public
          DoorMat::Session.current_session.public_computer!
        else
          DoorMat::Session.current_session.private_computer!
        end

        # User requested to be remembered
        if DoorMat.configuration.allow_remember_me_feature && remember_me
          DoorMat::Session.current_session.remember_me! unless (
            DoorMat.configuration.remember_me_require_private_computer_confirmation &&
              DoorMat::Session.current_session.public_computer?
          )
        end

        actor.sessions << DoorMat::Session.current_session
        DoorMat::Session.current_session.set_up(cookies)
        true
      end

    end
  end
end

