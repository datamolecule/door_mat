require 'spec_helper'

module DoorMat
  describe ForgotPasswordsController do
    routes { DoorMat::Engine.routes }
    let(:user) { {email: 'user@example.com', password: 'k#dkvKfdj38g!'} }

    describe '#create' do
      render_views

      it 'render new if the user input validation fails' do
        post :create, forgot_password: {email: 'email'}
        expect(response).to have_http_status(200)
        expect(response.body).to match(/Email is invalid/)
      end

      it 'redirects the user to the same page no matter if the email exists or not in the system' do
        _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

        post :create, {"utf8"=>"✓", "forgot_password"=>{"email"=>user[:email]} }
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/forgot_password_verification_mail_sent')

        post :create, {"utf8"=>"✓", "forgot_password"=>{"email"=>"not_an_actual_user@example.com"} }
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/forgot_password_verification_mail_sent')
      end

    end

    describe '#reset_password' do
      render_views

      it 'render choose_new_password if something is wrong with the user inputs' do
        post :reset_password, forgot_password: {email: 'email'}
        expect(response).to have_http_status(200)
        expect(response.body).to match(/Password is too short/)
      end

      it 'redirects the user to the sign in url if the password reset is successful' do
        allow(DoorMat::Process::ResetPassword).to receive(:with).and_return(true)
        post :reset_password, forgot_password: {email: user[:email], password: user[:password], password_confirmation: user[:password]}
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/sign_in')
      end

      it 'redirect the user to the start of the forgot password recovery process if an error occurs' do
        allow(DoorMat::Process::ResetPassword).to receive(:with).and_return(false)
        post :reset_password, forgot_password: {email: user[:email], password: user[:password], password_confirmation: user[:password]}
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/forgot_password')
      end

    end

  end
end
