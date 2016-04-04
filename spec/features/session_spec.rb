require 'spec_helper'
require 'tempfile'

module DoorMat

  RSpec.describe 'Actor lifecycle', :type => :feature do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    let(:user) { {email: 'user@example.com', password: 'k#dkvKfdj38g!', new_password: 'new_k#dkvKfdj38g!'} }

    it 'shows the signed in user email if leak email address is true' do
      DoorMat.configuration.leak_email_address_at_reconfirm = true
      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

      visit '/sign_in'
      expect(page.find('#sign_in_email').value).to eq('')
      fill_sign_in_form(user[:email], user[:password])
      expect(page.current_path).to match(/session_protected_page/)

      wait_less_than_public_computer_session_timeout
      visit '/account/show'
      expect(page.body).to have_content('Reconfirm Password')
      expect(page.body).to have_content(user[:email])

      DoorMat.configuration.leak_email_address_at_reconfirm = false
    end

    it 'does not show the user email if leak email is false' do
      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

      visit '/sign_in'
      expect(page.find('#sign_in_email').value).to eq('')
      fill_sign_in_form(user[:email], user[:password])
      expect(page.current_path).to match(/session_protected_page/)

      wait_less_than_public_computer_session_timeout
      click_link 'Show Account'
      expect(page.body).to have_content('Reconfirm Password')
      expect(page.body).not_to have_content(user[:email])
    end

    it 'allows the user to change the account password' do
      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

      visit '/sign_in'
      fill_sign_in_form(user[:email], user[:password])
      click_link 'Show Account'

      click_link 'Change Password'

      expect(page.body).to have_content('New password confirmation')
      fill_in 'change_password_old_password', with: 'wrong_password'
      fill_in 'change_password_new_password', with: user[:new_password]
      fill_in 'change_password_new_password_confirmation', with: user[:new_password]
      click_button 'Change Password'

      expect(page.body).to have_content('New password confirmation')
      fill_in 'change_password_old_password', with: user[:password]
      fill_in 'change_password_new_password', with: user[:new_password]
      fill_in 'change_password_new_password_confirmation', with: user[:new_password]
      click_button 'Change Password'
      expect(page.body).to have_content('You have successfully changed your password')

      visit '/account/show'
      click_link 'Sign Out'

      visit '/sign_in'
      fill_sign_in_form(user[:email], user[:new_password], false)
      expect(page.body).to have_content('Static#session_protected_page')
    end

    it 'times out a session if the user is not active for too long' do
      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

      visit '/sign_in'
      fill_sign_in_form(user[:email], user[:password])
      expect(page.body).to have_content('Static#session_protected_page')

      wait_longer_than_public_computer_session_timeout
      click_link 'Show Account'
      expect(page.body).not_to have_content('Account#show')
      expect(page.body).to have_content('Sign In')
    end

    it 'does not time out a session if the user if actively used but still require password reconfirm' do
      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

      visit '/sign_in'
      fill_sign_in_form(user[:email], user[:password])
      expect(page.body).to have_content('Static#session_protected_page')

      wait_less_than_public_computer_session_timeout
      click_link 'Show Account'
      expect(page.body).to have_content('Reconfirm Password')

      fill_in 'password', with: 'wrong_password'
      click_button 'Reconfirm'
      expect(page.body).not_to have_content('Account#show')
      fill_in 'password', with: user[:password]
      click_button 'Reconfirm'
      expect(page.body).to have_content('Account#show')

      wait_two_minutes
      visit '/account/show'
      expect(page.body).to have_content('Account#show')

      wait_longer_than_public_computer_session_timeout
      visit '/account/show'
      expect(page.body).not_to have_content('Account#show')
      expect(page.body).to have_content('Sign In')
    end

    it 'can terminate other session if logged in from many sessions at the same time' do
      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])
      
      Capybara.session_name = 'device_1'
      visit '/sign_in'
      fill_sign_in_form(user[:email], user[:password])
      click_link 'Show Account'
      expect(page.body).to have_content('Account#show')
      expect(page).not_to have_button('Terminate')

      Capybara.session_name = 'device_2'
      visit '/sign_in'
      fill_sign_in_form(user[:email], user[:password])
      click_link 'Show Account'
      expect(page.body).to have_content('Account#show')

      Capybara.session_name = 'device_1'
      visit '/account/show'
      expect(page.body).to have_content('Account#show')

      Capybara.session_name = 'device_2'
      visit '/account/show'
      expect(page.body).to have_content('Account#show')
      expect(page).to have_button('Terminate')
      click_button 'Terminate'
      reload_page

      Capybara.session_name = 'device_1'
      visit '/account/show'
      expect(page).to have_content('Sign In')
    end

    it 'terminates a session where the session key is wrong' do
      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

      Capybara.session_name = 'device_1'
      visit '/sign_in'
      fill_sign_in_form(user[:email], user[:password])
      click_link 'Show Account'
      expect(page.body).to have_content('Account#show')
      cookie_session_key = get_me_the_cookie('session_key') # steal session key
      expect(DoorMat::Session.count).to eq(1)

      Capybara.session_name = 'device_2'
      visit '/sign_in'
      fill_sign_in_form(user[:email], user[:password])
      click_link 'Show Account'
      expect(page.body).to have_content('Account#show')

      expect(DoorMat::Session.count).to eq(2)
      create_cookie('session_key', cookie_session_key[:value]) # try to use it with a different session

      reload_page
      expect(page).to have_content('Sign In')
      expect(DoorMat::Session.count).to eq(1)
    end

    it 'Sign up, confirm email, download recovery key file and do password recovery' do
      visit '/sign_up'
      fill_sign_up_form(user[:email], user[:password])

      expect(unread_emails_for(user[:email]).size).to eq(parse_email_count(1))
      e = open_last_email_for(user[:email])
      confirm_email_url = links_in_email(e).select {|url| /confirm_email/.match(url)}.first
      visit confirm_email_url

      visit '/account/show'
      click_link 'Sign Out'

      visit '/sign_in'

      # Obtain the recovery key 'inline' instead of from 'attachment'
      # http://stackoverflow.com/questions/15739423/downloading-file-to-specific-folder-using-capybara-and-poltergeist-driver
      # https://github.com/ariya/phantomjs/issues/10052
      fill_sign_in_form(user[:email], user[:password], false)
      click_link 'Show Account'
      set_hidden_input_value('#disposition', 'inline')
      click_button 'Download'
      recovery_key = page.find(:css, 'pre').text

      visit '/account/show'
      click_link 'Sign Out'
      click_link 'Sign In'
      click_link 'Forgot your password?'
      fill_in 'forgot_password_email', with: user[:email]
      click_button 'Reset'
      expect(page.body).to have_content('forgot_password_verification_mail_sent')
      wait_two_minutes

      # This new request before forgot_password_link_request_delay does not send a new email
      visit '/sign_in'
      click_link 'Forgot your password?'
      fill_in 'forgot_password_email', with: user[:email]
      click_button 'Reset'
      expect(page.body).to have_content('forgot_password_verification_mail_sent')

      expect(unread_emails_for(user[:email]).size).to eq(parse_email_count(1))

      e = open_last_email_for(user[:email])
      confirm_email_url = links_in_email(e).select {|url| /choose_new_password/.match(url)}.first
      visit confirm_email_url

      fill_in 'forgot_password_email', with: user[:email]
      fill_in 'forgot_password_password', with: user[:new_password]
      fill_in 'forgot_password_password_confirmation', with: user[:new_password]

      Tempfile.open('prefix', Rails.root.join('tmp') ) do |f|
        f.print(recovery_key)
        f.flush
        f.close

        attach_file('forgot_password_recovery_key', f.path)
        click_button 'Reset'
      end

      fill_sign_in_form(user[:email], user[:new_password], false)
      click_link 'Show Account'
      expect(page.body).to have_content('Click below to download your recovery key')

    end

    it 'Sign up, confirm email, download recovery key file and do password recovery but wait too long before using the recovery link' do
      visit '/sign_up'
      fill_sign_up_form(user[:email], user[:password])

      expect(unread_emails_for(user[:email]).size).to eq(parse_email_count(1))
      e = open_last_email_for(user[:email])
      confirm_email_url = links_in_email(e).select {|url| /confirm_email/.match(url)}.first
      visit confirm_email_url

      visit '/account/show'
      click_link 'Sign Out'

      visit '/sign_in'

      # Obtain the recovery key 'inline' instead of from 'attachment'
      # http://stackoverflow.com/questions/15739423/downloading-file-to-specific-folder-using-capybara-and-poltergeist-driver
      # https://github.com/ariya/phantomjs/issues/10052
      fill_sign_in_form(user[:email], user[:password], false)
      click_link 'Show Account'
      set_hidden_input_value('#disposition', 'inline')
      click_button 'Download'
      recovery_key = page.find(:css, 'pre').text

      visit '/account/show'
      click_link 'Sign Out'
      click_link 'Sign In'
      click_link 'Forgot your password?'
      fill_in 'forgot_password_email', with: user[:email]
      click_button 'Reset'
      expect(page.body).to have_content('forgot_password_verification_mail_sent')

      expect(unread_emails_for(user[:email]).size).to eq(parse_email_count(1))
      e = open_last_email_for(user[:email])
      confirm_email_url = links_in_email(e).select {|url| /choose_new_password/.match(url)}.first
      wait_two_days
      visit confirm_email_url

      fill_in 'forgot_password_email', with: user[:email]
      fill_in 'forgot_password_password', with: user[:new_password]
      fill_in 'forgot_password_password_confirmation', with: user[:new_password]

      Tempfile.open('prefix', Rails.root.join('tmp') ) do |f|
        f.print(recovery_key)
        f.flush
        f.close

        attach_file('forgot_password_recovery_key', f.path)
        click_button 'Reset'
      end

      expect(page.body).to have_content('Please make a new request')

    end

    it 'Sign up and request a new email reconfirmation email, add a new email and attempt to use it to visit account/show before it is confirmed' do
      visit '/sign_up'
      fill_sign_up_form(user[:email], user[:password])

      expect(unread_emails_for(user[:email]).size).to eq(parse_email_count(1))
      _ = open_last_email_for(user[:email])

      click_link 'Show Account'
      wait_longer_than_public_computer_session_timeout
      click_button 'Resend confirmation email'
      expect(page.current_path).to match(/sign_in/)

      fill_sign_in_form(user[:email], user[:password])
      click_link 'Show Account'
      click_button 'Resend confirmation email'

      expect(unread_emails_for(user[:email]).size).to eq(parse_email_count(1))
      e = open_last_email_for(user[:email])
      confirm_email_url = links_in_email(e).select {|url| /confirm_email/.match(url)}.first
      visit confirm_email_url

      visit '/account/show'
      expect(DoorMat::Email.all.first.primary?).to be_truthy
      expect(page.body).to match(/You are currently logged in as:.*user@example.com.*User Name/m)

      click_link 'Add new email'
      fill_in 'email_address', with: 'new_user@example.com'
      click_button 'Add email'
      click_link 'Sign Out'

      visit '/sign_in'

      fill_sign_in_form('new_user@example.com', user[:password])
      click_link 'Show Account'
      expect(page.body).to have_content('Please confirm your email address')

      expect(unread_emails_for('new_user@example.com').size).to eq(parse_email_count(1))
      e = open_last_email_for('new_user@example.com')
      confirm_email_url = links_in_email(e).select {|url| /confirm_email/.match(url)}.first
      visit confirm_email_url

      visit '/account/show'
      expect(DoorMat::Email.all.last.confirmed?).to be_truthy
      expect(page.body).to match(/You are currently logged in as:.*new_user@example.com.*User Name/m)
    end

  end
end
