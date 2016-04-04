module DoorMat
  class SessionsController < DoorMat::ApplicationController
    before_action :require_confirmed_email

    # This is to let the user terminate an existing session from a different browser or device
    # see sign_in#destroy for the termination of the current active session in use
    def terminate
      session_guid = params[:guid]
      Session.current_session.actor.sessions.where(hashed_token: session_guid).each do |session|
        session.destroy
      end

      redirect_to :back
    end

  end
end
