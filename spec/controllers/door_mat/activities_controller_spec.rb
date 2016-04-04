require 'spec_helper'

module DoorMat
  describe ActivitiesController do
    routes { DoorMat::Engine.routes }
    let(:user) { {email: 'user@example.com', password: 'k#dkvKfdj38g!'} }

    describe '#resend_email_confirmation' do
      it 'redirects to :back if the email is invalid' do
        _, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        @request.headers["HTTP_REFERER"] = '/some_path'
        post :resend_email_confirmation, {email: 'invalid_email'}
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end

      it 'redirects to :confirm_email_success if the email is already confirmed' do
        actor, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        @request.headers["HTTP_REFERER"] = '/some_path'
        post :resend_email_confirmation, {email: actor.current_email.to_urlsafe_encoded}
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/confirm_email_success')
      end

      it 'redirects to :back if the address is not confirmed' do
        actor, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        email = DoorMat::Email.for('new_address@example.com')
        actor.emails << email

        @request.headers["HTTP_REFERER"] = '/some_path'
        post :resend_email_confirmation, {email: email.to_urlsafe_encoded}
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end


      it 'redirects to main app root url if the address is not confirmed and HTTP_REFERER is not set' do
        actor, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        email = DoorMat::Email.for('new_address@example.com')
        actor.emails << email

        post :resend_email_confirmation, {email: email.to_urlsafe_encoded}
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/')
      end

    end

    describe '#confirm_email' do
      it 'redirects to :back after an invalid email confirmation request' do
        _, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        @request.headers["HTTP_REFERER"] = '/some_path'
        get :confirm_email, {token: 'invalid_token', email: 'invalid_email'}
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end
    end

    describe '#download_recovery_key' do
      it 'redirects to :back after an invalid download request' do
        _, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        @request.headers["HTTP_REFERER"] = '/some_path'
        post :download_recovery_key
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end
    end

  end
end
