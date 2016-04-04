require 'spec_helper'

module DoorMat

  RSpec.describe 'Actor lifecycle', :type => :feature do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    let(:admin) { {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd} }

    it 'Request token to access resource without creating an account' do

      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

      visit '/draw_results'
      expect(page.current_url).to match(/big_ticket/)

      visit '/big_ticket'
      expect(page.body).to match(/Enter your email address twice in the form below/)

      address = 'user@example.com'
      manage_list_url = fill_access_token_form('User', address)

      visit manage_list_url

      expect(page.body).to match(/Would you like to/)
      click_link 'Play a game?'

      select '5', :from => 'door'
      click_button 'Next'

      select '5', :from => 'door'
      click_button 'Next'

      expect(page.body).to match(/the winning door/)

      visit '/final_result'
      expect(page.current_path).to match(/big_ticket/)

      visit '/show_loosing_door'
      expect(page.current_path).to match(/big_ticket/)

      visit '/play_game'
      expect(page.current_path).to match(/big_ticket/)
    end

    it 'Ensure previous session gets terminated if user request a new one' do
      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

      visit '/draw_results'
      expect(page.current_url).to match(/big_ticket/)

      email = 'user@example.com'
      expect(unread_emails_for(email).size).to eq(parse_email_count(0))

      manage_list_url = fill_access_token_form('User', email)

      visit manage_list_url

      expect(page.current_url).to match(/draw_results/)
      visit '/draw_results'
      expect(page.current_url).to match(/draw_results/)

      # Steal the current cookie
      cookie_token = get_me_the_cookie('token')
      visit '/big_ticket'

      # Get a new cookie
      manage_list_url = fill_access_token_form('User', email)
      visit manage_list_url

      expect(page.current_url).to match(/draw_results/)
      visit '/draw_results'
      expect(page.current_url).to match(/draw_results/)

      # Trying to reuse the old cookie fails
      create_cookie('token', cookie_token[:value])
      visit '/draw_results'
      expect(page.current_url).not_to match(/draw_results/)
    end


    it 'fails the multipass email validation for user@example.com' do
      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

      visit '/multipass'
      expect(page.current_url).to match(/multipass/)
      expect(page.body).to match(/Enter your email address twice in the form below/)

      address = 'user@example.com'
      manage_list_url = fill_access_token_form('User', address)

      visit manage_list_url

      expect(page.body).to match(/Something looks wrong with your access token/)
    end



    it 'gives Leeloo a multipass' do
      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])

      visit '/multipass'
      expect(page.current_url).to match(/multipass/)
      expect(page.body).to match(/Enter your email address twice in the form below/)

      address = 'leeloo@example.com'
      manage_list_url = fill_access_token_form('Leeloo', address)

      visit manage_list_url

      expect(page.body).to match(/Would you like to/)
      click_link 'Play a game?'

      select '5', :from => 'door'
      click_button 'Next'

      select '5', :from => 'door'
      click_button 'Next'

      expect(page.body).to match(/the winning door/)

      visit '/final_result'
      expect(page.current_path).to match(/big_ticket/)

      visit '/show_loosing_door'
      expect(page.current_path).to match(/big_ticket/)

      visit '/play_game'
      expect(page.current_path).to match(/big_ticket/)

      visit '/draw_results'
      expect(page.current_path).to match(/big_ticket/)


      visit manage_list_url

      expect(page.body).to match(/Would you like to/)
      click_link 'Play a game?'

      select '5', :from => 'door'
      click_button 'Next'

      select '5', :from => 'door'
      click_button 'Next'

      expect(page.body).to match(/the winning door/)


      visit manage_list_url

      expect(page.body).to match(/Would you like to/)
      click_link 'Play a game?'

      select '5', :from => 'door'
      click_button 'Next'

      select '5', :from => 'door'
      click_button 'Next'

      expect(page.body).to match(/the winning door/)
    end

  end
end
