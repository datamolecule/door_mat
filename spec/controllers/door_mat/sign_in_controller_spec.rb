require 'spec_helper'

module DoorMat
  describe SignInController do
    routes { DoorMat::Engine.routes }
    let(:user) { {email: 'user@example.com', password: 'k#dkvKfdj38g!'} }

    describe '#create' do
      render_views

      it 'accepts a submission where email addresss and password correspond to an existing user' do
        _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

        post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Sign In"}
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/session_protected_page')
      end

      it 'rejects a submission where the email is not valid' do
        post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>"x", "password"=>user[:password], "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Sign In"}
        expect(response.body).to match(/Email is invalid/)
        expect(response.body).to match(/Could not sign you in based on the information provided/)
        expect(response).to have_http_status(200)
      end

      it 'rejects a submission where the password is blank' do
        post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>"", "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Sign In"}
        expect(response.body).to match(/Password is too short/)
        expect(response.body).to match(/Could not sign you in based on the information provided/)
        expect(response).to have_http_status(200)
      end

      it 'rejects a submission where the account does not exist' do
        post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Sign In"}
        expect(response.body).to match(/Could not sign you in based on the information provided/)
        expect(response).to have_http_status(200)
      end

      it 'rejects a submission where the password is wrong' do
        _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

        post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>"wrong_password", "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Sign In"}
        expect(response.body).to match(/Could not sign you in based on the information provided/)
        expect(response).to have_http_status(200)
      end

      it 'fails if allow forgery protection is true' do
        _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

        ActionController::Base.allow_forgery_protection = true
        @request.headers["HTTP_REFERER"] = "/sign_in"

        expect do
          post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Sign In"}
        end.to raise_error(ActionController::InvalidAuthenticityToken)

        ActionController::Base.allow_forgery_protection = false
      end

      describe 'the public, private and remember me behavior' do

        describe 'With default config' do

          before(:context) do
            reset_default_config
          end
          after (:context) do
            reset_default_config
          end

          it 'requests public_computer without remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.public_computer?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

          it 'requests public_computer with remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"1", "remember_me"=>"1"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.public_computer?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

          it 'requests private_computer without remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"0", "remember_me"=>"0"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.private_computer?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

          it 'requests private_computer with remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"0", "remember_me"=>"1"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.private_computer?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

        end

        describe 'When remember_me is allowed only on a private computer' do

          before(:context) do
            reset_default_config
            DoorMat.configuration.allow_remember_me_feature = true
          end
          after (:context) do
            reset_default_config
          end

          it 'requests public_computer without remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.public_computer?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

          it 'requests public_computer with remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"1", "remember_me"=>"1"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.public_computer?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

          it 'requests private_computer without remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"0", "remember_me"=>"0"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.private_computer?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

          it 'requests private_computer with remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"0", "remember_me"=>"1"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.remember_me?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

        end

        describe 'When remember_me is allowed on both public and private computers' do

          before(:context) do
            reset_default_config
            DoorMat.configuration.allow_remember_me_feature = true
            DoorMat.configuration.remember_me_require_private_computer_confirmation = false
          end
          after (:context) do
            reset_default_config
          end

          it 'requests public_computer without remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.public_computer?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

          it 'requests public_computer with remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"1", "remember_me"=>"1"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.remember_me?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

          it 'requests private_computer without remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"0", "remember_me"=>"0"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.private_computer?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

          it 'requests private_computer with remember_me' do
            _ = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

            post :create, {"utf8"=>"✓", "sign_in"=>{"email"=>user[:email], "password"=>user[:password], "is_public"=>"0", "remember_me"=>"1"}, "commit"=>"Sign In"}
            expect(DoorMat::Session.first.remember_me?).to be true
            expect(response).to have_http_status(302)
            expect(response).to redirect_to('/session_protected_page')
          end

        end

      end

    end

  end
end
