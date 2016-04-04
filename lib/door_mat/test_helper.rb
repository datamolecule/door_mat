module DoorMat
  module TestHelper

    def self.create_signed_up_actor_with_confirmed_email_address(address="me@example.com", password="n7f3d;3#)")
      actor, _ = create_signed_in_actor_with_confirmed_email_address(address, password)
      DoorMat::Session.clear_current_session
      actor
    end

    def self.create_signed_in_actor_with_confirmed_email_address(address="me@example.com", password="n7f3d;3#)")
      DoorMat::Session.clear_current_session
      actor = DoorMat::Actor.create_with(password)

      email = DoorMat::Email.for(address)
      email.status = :primary

      session = DoorMat::Session.new
      session.ip = "request.remote_ip"
      session.agent = "request.user_agent"
      actor.current_email = email

      RequestStore.store[:current_session] = session.initialize_with(actor, password)

      actor.sessions << DoorMat::Session.current_session
      actor.emails << email

      # setup public key pairs
      actor.setup_public_key_pairs(DoorMat::Session.current_session)

      actor.save!

      DoorMat::ActivityDownloadRecoveryKey.for(actor)
      [actor, RequestStore.store[:current_session]]
    end

    def self.sign_in_existing_actor(address="me@example.com", password="n7f3d;3#)")
      DoorMat::Session.clear_current_session
      actor = DoorMat::Actor.authenticate_with(address, password)

      session = DoorMat::Session.new
      session.ip = "request.remote_ip"
      session.agent = "request.user_agent"

      RequestStore.store[:current_session] = session.initialize_with(actor, password)

      actor.sessions << DoorMat::Session.current_session
      actor.save!

      [actor, RequestStore.store[:current_session]]
    end

    def self.sign_out(session)
      session.destroy! if session.persisted?
      RequestStore.store[:current_session] = nil
    end

  end
end
