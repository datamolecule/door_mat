
Rails.application.config.to_prepare do
  DoorMat::Actor.class_eval do
    # Sample symmetric encryption
    has_one :user_detail, :dependent => :destroy
    has_many :games, :dependent => :destroy

    # Sample asymmetric (Public-key) encryption
    has_many :shared_keys, :dependent => :destroy
    has_many :shared_data, :through => :shared_keys
  end
end

DoorMat.configure do |config|
  config.sign_in_success_url = [:main_app, :session_protected_page_url]
  config.sign_up_success_url = [:main_app, :session_protected_page_url]
  config.add_email_success_url = [:main_app, :account_show_url]

  config.password_less_sessions = {
      password_less_defaults: {
          generic_redirect_url: [:main_app, :root_url]
      },
      big_ticket: {
          actor: {
              email: Rails.application.secrets.admin_account_email,
              password: Rails.application.secrets.admin_account_pwd
          },
          challenge: [:email],
          validate: false, # Anybody can play the game
          # validate: -> (address) { /@cheater.com\z/.match(address).blank? }, # Don't let those cheaters play the game...
          # validate: -> (address) { DoorMat::Email.count(address) > 0 }, # Must be a registered user to play the game...
          expiration_delay: 30.minutes, # (or 10.days, etc.) before the link expires
          status: :single_use, # or :multiple_use access token
          form_submit_path: [:main_app, :big_ticket_path],
          default_success_url: [:main_app, :draw_results_url],
          transitions: [:play_game]
      },
      play_game: {
          actor: {
              email: Rails.application.secrets.admin_account_email,
              password: Rails.application.secrets.admin_account_pwd
          },
          expiration_delay: 30.minutes,
          status: :single_use,
          transitions: [:show_loosing_door]
      },
      show_loosing_door: {
          actor: {
              email: Rails.application.secrets.admin_account_email,
              password: Rails.application.secrets.admin_account_pwd
          },
          expiration_delay: 30.minutes,
          status: :single_use
      },
      multipass: {
          actor: {
              email: Rails.application.secrets.admin_account_email,
              password: Rails.application.secrets.admin_account_pwd
          },
          challenge: [:email],
          validate: -> (address) { !/\Aleeloo@example.com\z/.match(address).blank? },
          expiration_delay: 1.day,
          status: :multiple_use,
          form_submit_path: [:main_app, :multipass_path],
          default_success_url: [:main_app, :draw_results_url],
          transitions: [:play_game]
      }
  }

  config.logger = Rails.logger
  config.mailer_from_address = Rails.application.secrets.mailer_address
end
