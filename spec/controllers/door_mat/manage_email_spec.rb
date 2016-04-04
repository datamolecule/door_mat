require 'spec_helper'

module DoorMat
  describe ManageEmailController do
    routes { DoorMat::Engine.routes }
    let(:user) { {email: 'user@example.com', password: 'k#dkvKfdj38g!'} }

    describe '#create' do
      render_views

      it 'redirects back after successfully adding a new email' do
        _, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        DoorMat.configuration.add_email_success_url = [ :request, :referer ]

        @request.headers["HTTP_REFERER"] = '/some_path'
        allow(DoorMat::ActivityConfirmEmail).to receive(:for)
        get :create, email: {address: 'other_user@example.com'}
        expect(flash[:notice]).to match(/New email address successfully added/)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
        DoorMat.configuration.add_email_success_url = [:main_app, :account_show_url]
      end

      it 'renders new if the submitted email is not valid' do
        _, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        @request.headers["HTTP_REFERER"] = '/some_path'
        get :create, email: {address: 'invalid_email'}
        expect(response.body).to match(/Address is invalid/)
        expect(response).to have_http_status(200)
      end

    end

    describe '#destroy' do

      it 'can delete the non primary email attached to an actor' do
        actor, session = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        email = actor.emails.first
        email.confirmed!

        other_email = DoorMat::Email.for('other_user@example.com')
        controller = Object.new
        allow(DoorMat::ActivityConfirmEmail).to receive(:for)
        DoorMat::Process::ManageEmail.add(other_email, actor, controller)
        other_email = actor.emails.last
        other_email.primary!

        TestHelper::sign_out(session)
        actor, _ = TestHelper::sign_in_existing_actor('other_user@example.com', user[:password])

        @request.headers["HTTP_REFERER"] = '/some_path'
        expect(actor.emails.count).to eq 2
        get :destroy, {email: email.to_urlsafe_encoded}
        expect(actor.emails.count).to eq 1
        expect(flash[:notice]).to match(/Email deleted/)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end

      it 'can not delete the email used to sign in to the current session' do
        actor, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        email = actor.emails.first
        email.confirmed!

        other_email = DoorMat::Email.for('other_user@example.com')
        controller = Object.new
        allow(DoorMat::ActivityConfirmEmail).to receive(:for)
        DoorMat::Process::ManageEmail.add(other_email, actor, controller)
        other_email = actor.emails.last
        other_email.primary!

        @request.headers["HTTP_REFERER"] = '/some_path'
        expect(actor.emails.count).to eq 2
        get :destroy, {email: email.to_urlsafe_encoded}
        expect(actor.emails.count).to eq 2
        expect(flash[:alert]).to match(/Can not delete the email address you are currently logged in with/)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end

      it 'can not delete the only email attached to an actor' do
        actor, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        email = actor.emails.first
        @request.headers["HTTP_REFERER"] = '/some_path'
        expect(actor.emails.count).to eq 1
        get :destroy, {email: email.to_urlsafe_encoded}
        expect(actor.emails.count).to eq 1
        expect(flash[:alert]).to match(/Can not delete the only email address associated with this account/)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end

      it 'can not delete the primary email attached to an actor' do
        actor, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])

        other_email = DoorMat::Email.for('other_user@example.com')
        controller = Object.new
        allow(DoorMat::ActivityConfirmEmail).to receive(:for)
        DoorMat::Process::ManageEmail.add(other_email, actor, controller)
        other_email.primary!

        @request.headers["HTTP_REFERER"] = '/some_path'
        expect(actor.emails.count).to eq 2
        get :destroy, {email: other_email.to_urlsafe_encoded}
        expect(actor.emails.count).to eq 2
        expect(flash[:alert]).to match(/Primary email can not be deleted/)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end

      it 'can not delete an email attached to a different actor' do
        actor = TestHelper::create_signed_up_actor_with_confirmed_email_address('other_user@example.com')
        email = actor.emails.first
        _, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        @request.headers["HTTP_REFERER"] = '/some_path'
        expect(actor.emails.count).to eq 1
        expect(DoorMat::Email.all.count).to eq 2
        get :destroy, {email: email.to_urlsafe_encoded}
        expect(actor.emails.count).to eq 1
        expect(DoorMat::Email.all.count).to eq 2
        expect(flash[:alert]).to match(/The specified email can not be deleted/)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end

      it 'can not delete an email that is not in the system' do
        actor, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        email = DoorMat::Email.for('other_user@example.com')
        @request.headers["HTTP_REFERER"] = '/some_path'
        expect(actor.emails.count).to eq 1
        get :destroy, {email: email.to_urlsafe_encoded}
        expect(actor.emails.count).to eq 1
        expect(flash[:alert]).to match(/The specified email can not be deleted/)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end

    end

    describe '#set_primary_email' do

      it 'succeed at setting the primary email' do
        actor, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
        email = actor.emails.first
        email.confirmed!

        other_email = DoorMat::Email.for('other_user@example.com')
        controller = Object.new
        allow(DoorMat::ActivityConfirmEmail).to receive(:for)
        DoorMat::Process::ManageEmail.add(other_email, actor, controller)
        other_email = actor.emails.last
        other_email.primary!

        @request.headers["HTTP_REFERER"] = '/some_path'
        post :set_primary_email, {email: email.to_urlsafe_encoded}
        expect(flash[:notice]).to match(/Primary email was set/)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end

      it 'fails at setting the primary email if the email is not confirmed' do
        actor, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])

        other_email = DoorMat::Email.for('other_user@example.com')
        controller = Object.new
        allow(DoorMat::ActivityConfirmEmail).to receive(:for)
        DoorMat::Process::ManageEmail.add(other_email, actor, controller)
        other_email = actor.emails.last
        other_email.not_confirmed!

        @request.headers["HTTP_REFERER"] = '/some_path'
        post :set_primary_email, {email: other_email.to_urlsafe_encoded}
        expect(flash[:alert]).to match(/Primary email could not be set/)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/some_path')
      end

    end

  end
end
