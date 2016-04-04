require 'spec_helper'

module DoorMat
  describe SignUpController do
    routes { DoorMat::Engine.routes }

    describe '#create' do
      render_views

      it 'accepts a valid submission for a new user' do
        post :create, {"utf8"=>"✓", "sign_up"=>{"email"=>"user@example.com", "password"=>"k#dkvKfdj38g!", "password_confirmation"=>"k#dkvKfdj38g!"}, "commit"=>"Sign Up"}
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/session_protected_page')
      end

      it 'accepts a submission for a new user with the same email and a different password until plausible_deniability_count is reached' do
        DoorMat::configuration.plausible_deniability_count = 2
        address = 'user@example.com'
        _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(address, 'k#dkvKfdj38g!')

        post :create, {"utf8"=>"✓", "sign_up"=>{"email"=>address, "password"=>'_____k#dkvKfdj38g!', "password_confirmation"=>'_____k#dkvKfdj38g!'}, "commit"=>"Sign Up"}
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/session_protected_page')
        DoorMat::configuration.plausible_deniability_count = 1
      end

      it 'rejects a submission where password confirmation does not match' do
        post :create, {"utf8"=>"✓", "sign_up"=>{"email"=>"user1@example.com", "password"=>"x", "password_confirmation"=>"y"}, "commit"=>"Sign Up"}
        expect(response.body).to match(/Password confirmation doesn&#39;t match Password/)
        expect(response.body).to match(/Could not sign you up based on the information provided/)
        expect(response).to have_http_status(200)
      end

      it 'rejects a submission where password is blank' do
        post :create, {"utf8"=>"✓", "sign_up"=>{"email"=>"user1@example.com", "password"=>"", "password_confirmation"=>""}, "commit"=>"Sign Up"}
        expect(response.body).to match(/Password is too short/)
        expect(response.body).to match(/Could not sign you up based on the information provided/)
        expect(response).to have_http_status(200)
      end

      it 'rejects a submission where the email is blank' do
        post :create, {"utf8"=>"✓", "sign_up"=>{"email"=>"", "password"=>"", "password_confirmation"=>""}, "commit"=>"Sign Up"}
        expect(response.body).to match(/Email is invalid/)
        expect(response.body).to match(/Could not sign you up based on the information provided/)
        expect(response).to have_http_status(200)
      end

      it 'rejects a submission where the email is invalid' do
        post :create, {"utf8"=>"✓", "sign_up"=>{"email"=>"bob", "password"=>"", "password_confirmation"=>""}, "commit"=>"Sign Up"}
        expect(response.body).to match(/Email is invalid/)
        expect(response.body).to match(/Could not sign you up based on the information provided/)
        expect(response).to have_http_status(200)
      end

      it 'reject a submission for a new user with the same email and password as an existing user' do
        address = 'user@example.com'
        password = 'k#dkvKfdj38g!'
        _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(address, password)

        post :create, {"utf8"=>"✓", "sign_up"=>{"email"=>address, "password"=>password, "password_confirmation"=>password}, "commit"=>"Sign Up"}
        expect(response.body).to match(/Could not sign you up based on the information provided/)
        expect(response).to have_http_status(200)
      end

      it 'lets a user sign in through the sign up form if explicitly allowed' do
        DoorMat.configuration.allow_sign_in_from_sign_up_form = true
        address = 'user@example.com'
        password = 'k#dkvKfdj38g!'
        _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(address, password)

        post :create, {"utf8"=>"✓", "sign_up"=>{"email"=>address, "password"=>password, "password_confirmation"=>password}, "commit"=>"Sign Up"}
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/session_protected_page')
        DoorMat.configuration.allow_sign_in_from_sign_up_form = false
      end

      it 'for a new user with the same email and a different password if the plausible_deniability_count is reached mark the email as not_available' do
        address = 'user@example.com'
        _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(address, 'k#dkvKfdj38g!')

        post :create, {"utf8"=>"✓", "sign_up"=>{"email"=>address, "password"=>'_____k#dkvKfdj38g!', "password_confirmation"=>'_____k#dkvKfdj38g!'}, "commit"=>"Sign Up"}
        expect(Email.last.not_available?).to be true
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/session_protected_page')
      end

    end

  end
end
