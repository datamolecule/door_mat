require 'spec_helper'

module DoorMat

  RSpec.describe 'the remember me feature', :type => :feature do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    let(:admin) { {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd} }
    let(:user) { {name: 'Alice', email: 'user@example.com', password: 'k#dkvKfdj38g!', new_password: 'new_k#dkvKfdj38g!'} }

    describe 'session access control across time' do

      describe 'with default config' do

        before(:context) do
          reset_default_config
        end
        after (:context) do
          reset_default_config
        end

        describe 'login on public computer without remember me' do

          before (:example) do
            is_public_computer = true
            remember_me = false

            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])
            visit '/sign_in'
            fill_sign_in_form(user[:email], user[:password], is_public_computer, remember_me)
          end

          it 'requires a sign in if I wait longer than the public computer timeout without interacting with the site' do
            wait_less_than_public_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_longer_than_public_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/sign_in/)
          end

        end

      end

      describe 'with remember_me enabled only on a private computer session' do

        before(:context) do
          reset_default_config
          DoorMat.configuration.allow_remember_me_feature = true
        end
        after (:context) do
          reset_default_config
        end

        describe 'login on public computer without remember me' do

          before (:example) do
            is_public_computer = true
            remember_me = false

            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])
            visit '/sign_in'
            fill_sign_in_form(user[:email], user[:password], is_public_computer, remember_me)
          end

          it 'requires a sign in if I wait longer than the public computer timeout without interacting with the site' do
            wait_less_than_public_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_longer_than_public_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/sign_in/)
          end

        end

        describe 'login on public computer with remember me' do

          before (:example) do
            is_public_computer = true
            remember_me = true

            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])
            visit '/sign_in'
            fill_sign_in_form(user[:email], user[:password], is_public_computer, remember_me)
          end

          it 'requires a sign in if I wait longer than the public computer timeout without interacting with the site' do
            wait_less_than_public_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_longer_than_public_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/sign_in/)
          end

        end

        describe 'login on private computer without remember me' do

          before (:example) do
            is_public_computer = false
            remember_me = false

            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])
            visit '/sign_in'
            fill_sign_in_form(user[:email], user[:password], is_public_computer, remember_me)
          end

          it 'requires a sign in if I wait longer than the private computer timeout without interacting with the site' do
            wait_less_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_longer_than_private_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/sign_in/)
          end

        end

        describe 'login on private computer with remember me' do

          before (:example) do
            is_public_computer = false
            remember_me = true

            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])
            visit '/sign_in'
            fill_sign_in_form(user[:email], user[:password], is_public_computer, remember_me)
          end

          it 'requires a sign in if I wait longer than the private computer timeout without interacting with the site' do
            wait_less_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_longer_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_less_than_remember_me_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_days
            reload_page
            expect(page.current_path).to match(/sign_in/)
          end

        end

      end


      describe 'with remember_me enabled on any session' do

        before(:context) do
          reset_default_config
          DoorMat.configuration.allow_remember_me_feature = true
          DoorMat.configuration.remember_me_require_private_computer_confirmation = false
        end
        after (:context) do
          reset_default_config
        end

        describe 'login on public computer without remember me' do

          before (:example) do
            is_public_computer = true
            remember_me = false

            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])
            visit '/sign_in'
            fill_sign_in_form(user[:email], user[:password], is_public_computer, remember_me)
          end

          it 'requires a sign in if I wait longer than the public computer timeout without interacting with the site' do
            wait_less_than_public_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_longer_than_public_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/sign_in/)
          end

        end

        describe 'login on public computer with remember me' do

          before (:example) do
            is_public_computer = true
            remember_me = true

            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])
            visit '/sign_in'
            fill_sign_in_form(user[:email], user[:password], is_public_computer, remember_me)
          end

          it 'requires a sign in if I wait longer than the public computer timeout without interacting with the site' do
            wait_less_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_longer_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_less_than_remember_me_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_days
            reload_page
            expect(page.current_path).to match(/sign_in/)
          end

        end

        describe 'login on private computer without remember me' do

          before (:example) do
            is_public_computer = false
            remember_me = false

            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])
            visit '/sign_in'
            fill_sign_in_form(user[:email], user[:password], is_public_computer, remember_me)
          end

          it 'requires a sign in if I wait longer than the private computer timeout without interacting with the site' do
            wait_less_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_longer_than_private_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/sign_in/)
          end

        end

        describe 'login on private computer with remember me' do

          before (:example) do
            is_public_computer = false
            remember_me = true

            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])
            visit '/sign_in'
            fill_sign_in_form(user[:email], user[:password], is_public_computer, remember_me)
          end

          it 'requires a sign in if I wait longer than the private computer timeout without interacting with the site' do
            wait_less_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_longer_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_less_than_remember_me_timeout
            reload_page
            expect(page.body).to have_content('Static#session_protected_page')
            wait_two_days
            reload_page
            expect(page.current_path).to match(/sign_in/)
          end

        end

      end


    end



    describe 'access_token access control across time' do

      describe 'with default config' do

        before(:context) do
          reset_default_config
        end
        after (:context) do
          reset_default_config
        end

        describe 'login on public computer without remember me' do

          before (:example) do
            is_public_computer = true
            remember_me = false

            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

            visit '/big_ticket'
            manage_list_url = fill_access_token_form(user[:name], user[:email], user[:email], is_public_computer, remember_me)

            visit manage_list_url
          end

          it 'requires a sign in if I wait longer than the public computer timeout without interacting with the site' do
            wait_longer_than_public_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/big_ticket/)
          end

          it 'requires a sign in if I wait longer than the public computer timeout without interacting with the site' do
            wait_less_than_public_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_longer_than_public_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/big_ticket/)
          end

        end

      end
      
      describe 'with remember_me enabled only on a private computer session' do

        before(:context) do
          reset_default_config
          DoorMat.configuration.allow_remember_me_feature = true
        end
        after (:context) do
          reset_default_config
        end

        describe 'login on public computer without remember me' do

          before (:example) do
            is_public_computer = true
            remember_me = false

            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

            visit '/big_ticket'
            manage_list_url = fill_access_token_form(user[:name], user[:email], user[:email], is_public_computer, remember_me)
            visit manage_list_url
          end

          it 'requires a sign in if I wait longer than the public computer timeout without interacting with the site' do
            wait_less_than_public_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_longer_than_public_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/big_ticket/)
          end

        end

        describe 'login on public computer with remember me' do

          before (:example) do
            is_public_computer = true
            remember_me = true

            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

            visit '/big_ticket'
            manage_list_url = fill_access_token_form(user[:name], user[:email], user[:email], is_public_computer, remember_me)
            visit manage_list_url
          end

          it 'requires a sign in if I wait longer than the public computer timeout without interacting with the site' do
            wait_less_than_public_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_longer_than_public_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/big_ticket/)
          end

        end

        describe 'login on private computer without remember me' do

          before (:example) do
            is_public_computer = false
            remember_me = false

            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

            visit '/big_ticket'
            manage_list_url = fill_access_token_form(user[:name], user[:email], user[:email], is_public_computer, remember_me)
            visit manage_list_url
          end

          it 'requires a sign in if I wait longer than the private computer timeout without interacting with the site' do
            wait_less_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_longer_than_private_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/big_ticket/)
          end

        end

        describe 'login on private computer with remember me' do

          before (:example) do
            is_public_computer = false
            remember_me = true

            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

            visit '/big_ticket'
            manage_list_url = fill_access_token_form(user[:name], user[:email], user[:email], is_public_computer, remember_me)
            visit manage_list_url
          end

          it 'requires a sign in if I wait longer than the private computer timeout without interacting with the site' do
            wait_less_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_longer_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_less_than_remember_me_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_days
            reload_page
            expect(page.current_path).to match(/big_ticket/)
          end

        end

      end


      describe 'with remember_me enabled on any session' do

        before(:context) do
          reset_default_config
          DoorMat.configuration.allow_remember_me_feature = true
          DoorMat.configuration.remember_me_require_private_computer_confirmation = false
        end
        after (:context) do
          reset_default_config
        end

        describe 'login on public computer without remember me' do

          before (:example) do
            is_public_computer = true
            remember_me = false

            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

            visit '/big_ticket'
            manage_list_url = fill_access_token_form(user[:name], user[:email], user[:email], is_public_computer, remember_me)
            visit manage_list_url
          end

          it 'requires a sign in if I wait longer than the public computer timeout without interacting with the site' do
            wait_less_than_public_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_longer_than_public_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/big_ticket/)
          end

        end

        describe 'login on public computer with remember me' do

          before (:example) do
            is_public_computer = true
            remember_me = true

            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

            visit '/big_ticket'
            manage_list_url = fill_access_token_form(user[:name], user[:email], user[:email], is_public_computer, remember_me)
            visit manage_list_url
          end

          it 'requires a sign in if I wait longer than the public computer timeout without interacting with the site' do
            wait_less_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_longer_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_less_than_remember_me_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_days
            reload_page
            expect(page.current_path).to match(/big_ticket/)
          end

        end

        describe 'login on private computer without remember me' do

          before (:example) do
            is_public_computer = false
            remember_me = false

            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

            visit '/big_ticket'
            manage_list_url = fill_access_token_form(user[:name], user[:email], user[:email], is_public_computer, remember_me)
            visit manage_list_url
          end

          it 'requires a sign in if I wait longer than the private computer timeout without interacting with the site' do
            wait_less_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_longer_than_private_computer_session_timeout
            reload_page
            expect(page.current_path).to match(/big_ticket/)
          end

        end

        describe 'login on private computer with remember me' do

          before (:example) do
            is_public_computer = false
            remember_me = true

            admin = {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd}
            DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

            visit '/big_ticket'
            manage_list_url = fill_access_token_form(user[:name], user[:email], user[:email], is_public_computer, remember_me)
            visit manage_list_url
          end

          it 'requires a sign in if I wait longer than the private computer timeout without interacting with the site' do
            wait_less_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_minutes
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_longer_than_private_computer_session_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_less_than_remember_me_timeout
            reload_page
            expect(page.body).to have_content('Big ticket Winner')
            wait_two_days
            reload_page
            expect(page.current_path).to match(/big_ticket/)
          end

        end

      end

    end

  end
end
