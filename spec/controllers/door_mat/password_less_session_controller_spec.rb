require 'spec_helper'

module DoorMat
  describe PasswordLessSessionController do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    describe '#create' do
      render_views

      def accept_valid_token_get_request(via_post = true)
        admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
        DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

        post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/access_token/big_ticket')
        expect(DoorMat::AccessToken.first.single_use?).to be true

        e = open_last_email_for("user1@example.com")
        link_in_email = links_in_email(e).select {|url| /access_token/.match(url)}.first
        token = test_only_session_guid_anywhere_regex.match(link_in_email)[0]
        if via_post
          post :access_token_post, access_token: {token_for: :big_ticket, identifier: token}, use_route: :door_mat
        else
          get :access_token, token_for: :big_ticket, token: token, use_route: :door_mat
        end

        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/draw_results')
        expect(DoorMat::AccessToken.first.used?).to be true
      end

      it 'accepts a valid access token request via post' do
        accept_valid_token_get_request(via_post = true)
      end

      it 'accepts a valid access token request via get' do
        accept_valid_token_get_request(via_post = false)
      end

      def reject_token_request_that_fail_address_validation(via_post = true, validation_method = :reject_cheaters)
        admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
        DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

        case validation_method
          when :reject_cheaters
            user_address = 'cheat@cheater.com'
            DoorMat.configuration.password_less_sessions[:big_ticket][:validate] = -> (address) { /@cheater.com\z/.match(address).blank? } # Don't let those cheaters play the game...
          when :existing_members_only
            user_address = 'bob@example.com'
            DoorMat.configuration.password_less_sessions[:big_ticket][:validate] = -> (address) { DoorMat::Email.count_matching(address) > 0 } # Must be a registered user to play the game...
        end

        post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>user_address, "confirm_identifier"=>user_address}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/access_token/big_ticket')
        expect(DoorMat::AccessToken.first.single_use?).to be true

        e = open_last_email_for(user_address)
        link_in_email = links_in_email(e).select {|url| /access_token/.match(url)}.first
        token = test_only_session_guid_anywhere_regex.match(link_in_email)[0]
        if via_post
          post :access_token_post, access_token: {token_for: :big_ticket, identifier: token}, use_route: :door_mat
        else
          get :access_token, token_for: :big_ticket, token: token, use_route: :door_mat
        end

        expect(response).to have_http_status(200)
        expect(response.body).to match(/Something looks wrong with your access token/)
        expect(DoorMat::AccessToken.count).to eq(0)

        DoorMat.configuration.password_less_sessions[:big_ticket][:validate] = false
      end

      it 'reject token requests that fail address validation via post' do
        reject_token_request_that_fail_address_validation(via_post = true, validation_method = :reject_cheaters)
        reject_token_request_that_fail_address_validation(via_post = true, validation_method = :existing_members_only)
      end

      it 'reject token requests that fail address validation via get' do
        reject_token_request_that_fail_address_validation(via_post = false, validation_method = :reject_cheaters)
        reject_token_request_that_fail_address_validation(via_post = false, validation_method = :existing_members_only)
      end

      def accept_token_request_that_succeed_address_validation(via_post = true, validation_method = :reject_cheaters)
        admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
        DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

        user_address = 'bob@example.com'
        case validation_method
          when :reject_cheaters
            DoorMat.configuration.password_less_sessions[:big_ticket][:validate] = -> (address) { /@cheater.com\z/.match(address).blank? } # Don't let those cheaters play the game...
          when :existing_members_only
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user_address, 'user_password')
            DoorMat.configuration.password_less_sessions[:big_ticket][:validate] = -> (address) { DoorMat::Email.count_matching(address) > 0 } # Must be a registered user to play the game...
        end

        post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>user_address, "confirm_identifier"=>user_address}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/access_token/big_ticket')
        expect(DoorMat::AccessToken.first.single_use?).to be true

        e = open_last_email_for(user_address)
        link_in_email = links_in_email(e).select {|url| /access_token/.match(url)}.first
        token = test_only_session_guid_anywhere_regex.match(link_in_email)[0]
        if via_post
          post :access_token_post, access_token: {token_for: :big_ticket, identifier: token}, use_route: :door_mat
        else
          get :access_token, token_for: :big_ticket, token: token, use_route: :door_mat
        end

        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/draw_results')
        expect(DoorMat::AccessToken.first.used?).to be true

        DoorMat.configuration.password_less_sessions[:big_ticket][:validate] = false
      end

      it 'accept token requests that succeed address validation via post 1' do
        accept_token_request_that_succeed_address_validation(via_post = true, validation_method = :reject_cheaters)
      end

      it 'accept token requests that succeed address validation via post 2' do
        accept_token_request_that_succeed_address_validation(via_post = true, validation_method = :existing_members_only)
      end

      it 'accept token requests that succeed address validation via get 1' do
        accept_token_request_that_succeed_address_validation(via_post = false, validation_method = :reject_cheaters)
      end

      it 'accept token requests that succeed address validation via get 1' do
        accept_token_request_that_succeed_address_validation(via_post = false, validation_method = :existing_members_only)
      end

      def reject_malformed_late_inexistent_token_request(via_post = true)
        admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
        DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

        post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/access_token/big_ticket')
        expect(DoorMat::AccessToken.first.single_use?).to be true

        e = open_last_email_for("user1@example.com")
        link_in_email = links_in_email(e).select {|url| /access_token/.match(url)}.first
        token = test_only_session_guid_anywhere_regex.match(link_in_email)[0]

        if via_post
          post :access_token_post, access_token: {token_for: :big_ticket, identifier: token[0..-2]}, use_route: :door_mat
        else
          get :access_token, token_for: :big_ticket, token: token[0..-2], use_route: :door_mat
        end

        expect(response).to have_http_status(200)
        expect(response.body).to match(/format of your access token is invalid/)
        expect(DoorMat::AccessToken.first.used?).to be false

        wait_two_days

        if via_post
          post :access_token_post, access_token: {token_for: :big_ticket, identifier: token}, use_route: :door_mat
        else
          get :access_token, token_for: :big_ticket, token: token, use_route: :door_mat
        end

        expect(response).to have_http_status(200)
        expect(response.body).to match(/Something looks wrong with your access token/)
        expect(DoorMat::AccessToken.count).to eq(0)

        token[0..7] = 'deadbeef'
        if via_post
          post :access_token_post, access_token: {token_for: :big_ticket, identifier: token}, use_route: :door_mat
        else
          get :access_token, token_for: :big_ticket, token: token, use_route: :door_mat
        end

        expect(response).to have_http_status(200)
        expect(response.body).to match(/Something looks wrong with your access token/)
      end

      it 'it rejects a malformed, late or inexistent token request via post' do
        reject_malformed_late_inexistent_token_request(via_post = true)
      end

      it 'it rejects a malformed, late or inexistent token request via get' do
        reject_malformed_late_inexistent_token_request(via_post = false)
      end

      it 'raise an exception' do
        admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
        DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

        allow(DoorMat::PasswordLessSessionMailer).to receive(:send_token).and_raise(RuntimeError)
        expect {
        post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
        }.to raise_error(RuntimeError)
      end

      it 'rejects a submission where identifier and confirmation does not match' do
        post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"wrong_email@example.com"}, "commit"=>"Request access token", "token_for"=>:big_ticket}
        expect(response.body).to match(/The identifier provided does not match the confirmation field/)
        expect(response).to have_http_status(200)
      end

      it 'rejects a submission where identifier is blank' do
        post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"", "confirm_identifier"=>"user1@example.com"}, "commit"=>"Request access token", "token_for"=>:big_ticket}
        expect(response.body).to match(/The identifier can not be blank/)
        expect(response).to have_http_status(200)
      end

      it 'rejects a submission where identifier is not a valid address' do
        post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"invalid_identifier", "confirm_identifier"=>"user1@example.com"}, "commit"=>"Request access token", "token_for"=>:big_ticket}
        expect(response.body).to match(/The identifier is expected to be a valid email address/)
        expect(response).to have_http_status(200)
      end

      it 'rejects a submission where token_for is not valid' do
        post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com"}, "commit"=>"Request access token", "token_for"=>:invalid_token}
        expect(response.body).to match(/Could not create a request token based on the information provided/)
        expect(response).to have_http_status(200)
      end

      describe 'the public, private and remember me behavior' do

        describe 'With default config' do

          before(:context) do
            reset_default_config
          end
          after (:context) do
            reset_default_config
          end

          before(:example) do
            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])
          end

          it 'requests public_computer without remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.public_computer?).to be true
          end

          it 'requests public_computer with remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"1", "remember_me"=>"1"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.public_computer?).to be true
          end

          it 'requests private_computer without remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"0", "remember_me"=>"0"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.private_computer?).to be true
          end

          it 'requests private_computer with remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"0", "remember_me"=>"1"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.private_computer?).to be true
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

          before(:example) do
            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])
          end

          it 'requests public_computer without remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.public_computer?).to be true
          end

          it 'requests public_computer with remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"1", "remember_me"=>"1"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.public_computer?).to be true
          end

          it 'requests private_computer without remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"0", "remember_me"=>"0"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.private_computer?).to be true
          end

          it 'requests private_computer with remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"0", "remember_me"=>"1"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.remember_me?).to be true
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

          before(:example) do
            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])
          end

          it 'requests public_computer without remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"1", "remember_me"=>"0"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.public_computer?).to be true
          end

          it 'requests public_computer with remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"1", "remember_me"=>"1"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.remember_me?).to be true
          end

          it 'requests private_computer without remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"0", "remember_me"=>"0"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.private_computer?).to be true
          end

          it 'requests private_computer with remember_me' do
            post :create, {"utf8"=>"✓", "access_token"=>{"identifier"=>"user1@example.com", "confirm_identifier"=>"user1@example.com", "is_public"=>"0", "remember_me"=>"1"}, "commit"=>"Request access token", "token_for"=>:big_ticket}, use_route: :main_app
            expect(DoorMat::AccessToken.first.remember_me?).to be true
          end

        end

      end

    end

  end
end
