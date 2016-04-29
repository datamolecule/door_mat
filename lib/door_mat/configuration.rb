module DoorMat
  class Configuration

    attr_accessor \
    :mailer_from_address,
    :password_reconfirm_delay,
    :public_computer_access_session_timeout,
    :private_computer_access_session_timeout,
    :forgot_password_link_request_delay_minutes,
    :forgot_password_link_expiration_delay_minutes,
    :allow_remember_me_feature,
    :remember_me_require_private_computer_confirmation,
    :remember_me_max_day_count,
    :leak_email_address_at_reconfirm,
    :plausible_deniability_count,
    :max_email_count_per_actor,
    :define_door_mat_routes,
    :allow_redirect_to_requested_url,
    :lockdown_default_redirect_url,
    :sign_up_success_url,
    :sign_in_success_url,
    :add_email_success_url,
    :destroy_email_redirect_url,
    :set_primary_email_redirect_url,
    :resend_email_confirmation_redirect_url,
    :confirm_email_success_url,
    :change_password_success_url,
    :sign_out_success_url,
    :forgot_password_verification_mail_sent_url,
    :allow_sign_up,
    :allow_sign_in_from_sign_up_form,
    :transmit_cookies_only_over_https,
    :crypto_pbkdf2_salt_length,
    :crypto_pbkdf2_password_length,
    :crypto_pbkdf2_iterations,
    :crypto_bcrypt_cost,
    :crypto_secure_compare_default_length,
    :event_hook_before_sign_up,
    :event_hook_after_sign_up,
    :event_hook_after_failed_sign_up,
    :event_hook_before_sign_in,
    :event_hook_after_sign_in,
    :event_hook_after_failed_sign_in,
    :event_hook_before_confirm_email,
    :event_hook_after_confirm_email,
    :event_hook_after_failed_confirm_email,
    :event_hook_before_download_recovery_key,
    :event_hook_after_download_recovery_key,
    :event_hook_after_failed_download_recovery_key,
    :event_hook_before_sign_out,
    :event_hook_after_sign_out,
    :logger,
    :password_less_sessions

    def initialize
      @mailer_from_address = "noreply@example.com"

      # Controllers that require_password_reconfirm will only
      # allow the user in without requesting an additional sign-in if the user password
      # was last entered less than password_reconfirm_delay
      # minutes ago.
      # All sections of the site allowing access to or modification
      # of sensitive information or settings should be protected this way.
      # This includes operations resulting in
      # a financial transaction using stored or pre-authorized payment methods.
      @password_reconfirm_delay = 5

      # A session from a public computer will only last
      # until the browser is closed and will timeout
      # after public_computer_access_session_timeout
      # minutes of inactivity.
      @public_computer_access_session_timeout = 30

      # A session from a private computer will survive
      # a browser restart but will expire in the
      # browser and timeout on the system
      # after private_computer_access_session_timeout
      # minutes of inactivity.
      @private_computer_access_session_timeout = 60


      # To prevent email flooding, a new request for a recovery password
      # links will only be sent after the specified delay
      @forgot_password_link_request_delay_minutes = 30

      # Password recovery links older than this delay become invalid
      @forgot_password_link_expiration_delay_minutes = 30

      # Does the system allow the remember me feature?
      # High value target systems such as financial sites
      # should not allow the remember me feature.
      # Even when this feature is enabled, sensitive area of the site
      # should require users to re-authenticate using a
      # before_action -> {require_password_reconfirm()}
      # filter
      @allow_remember_me_feature = false

      # As a safety reminder, the user must confirm that they
      # are not loging in from a public computer before enabling
      # the remember me feature
      @remember_me_require_private_computer_confirmation = true

      # A session from a private computer for which the
      # cookie will remain for a number of days specified
      # by remember_me_max_day_count and automatically
      # renew the session for that period of time
      @remember_me_max_day_count = 30

      # Do not pre-populate the email address field
      # in the sign_in form while doing a password reconfirmation
      # as it could be considered to leak the information about which
      # email address was used to login to the system before the reconfirmation request
      @leak_email_address_at_reconfirm = false

      # How many different accounts a single email address can be associated with on the system
      @plausible_deniability_count = 1

      # How many different emails can be linked to an actor
      @max_email_count_per_actor = 2

      # Production systems should eventually redefine their own routes explicitly
      # instead of relying on those provided by the engine
      @define_door_mat_routes = true

      #
      @allow_redirect_to_requested_url = true

      # When specifying redirects in
      # config/initializers/door_mat.rb you can use:
      # [ :main_app, :__path__ ] or [:__engine_name_, :__path__] respectively to redirect to an
      # existing path defined in your main application or loaded engine.
      # [:main_app, :root_url] to redirect to the root of your main application.
      # [ :request, :referer ] for an alternative to redirect_to :back.
      @lockdown_default_redirect_url = [ :request, :referer ]
      @sign_up_success_url = [ :sign_up_success_url ]
      @sign_in_success_url = [ :sign_in_success_url ]
      @add_email_success_url = [ :add_email_success_url ]
      @destroy_email_redirect_url = [ :request, :referer ]
      @set_primary_email_redirect_url = [ :request, :referer ]
      @resend_email_confirmation_redirect_url = [ :request, :referer ]
      @confirm_email_success_url = [ :confirm_email_success_url ]
      @change_password_success_url = [ :change_password_success_url ]
      @sign_out_success_url = [ :sign_out_success_url ]
      @forgot_password_verification_mail_sent_url = [ :forgot_password_verification_mail_sent_url ]

      @allow_sign_up = true
      @allow_sign_in_from_sign_up_form = false

      @transmit_cookies_only_over_https = true

      @crypto_pbkdf2_salt_length = 32
      @crypto_pbkdf2_password_length = 32
      @crypto_pbkdf2_iterations = 10_000

      @crypto_bcrypt_cost = 12

      @crypto_secure_compare_default_length = 1024


      @event_hook_before_sign_up = []
      @event_hook_after_sign_up = []
      @event_hook_after_failed_sign_up = []
      @event_hook_before_sign_in = []
      @event_hook_after_sign_in = []
      @event_hook_after_failed_sign_in = []
      @event_hook_before_confirm_email = []
      @event_hook_after_confirm_email = [] # The confirmed DoorMat::Email is passed as function argument
      @event_hook_after_failed_confirm_email = []
      @event_hook_before_download_recovery_key = []
      @event_hook_after_download_recovery_key = []
      @event_hook_after_failed_download_recovery_key = []
      @event_hook_before_sign_out = []
      @event_hook_after_sign_out = []

      @logger = Rails.logger

      # By default, there are no password less sessions defined
      # see test_app/config/initializers/door_mat.rb for sample usage
      @password_less_sessions = {}

    end
  end

  def self.configuration
    @configuration ||= DoorMat::Configuration.new
  end

  def self.configure
    yield configuration
  end
end
