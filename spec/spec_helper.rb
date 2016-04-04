# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../test_app/config/environment", __FILE__)

require 'email_spec'
require 'rspec/rails'
require 'database_cleaner'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'factory_girl_rails'
require 'door_mat'
require 'door_mat/test_helper'
require 'byebug'
require 'show_me_the_cookies'
require 'timecop'

Rails.backtrace_cleaner.remove_silencers!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
# Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')
Dir[File.join(ENGINE_RAILS_ROOT, "spec/support/**/*.rb")].each {|f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.include FactoryGirl::Syntax::Methods # If you do not include FactoryGirl::Syntax::Methods in your test suite, then all factory_girl methods will need to be prefaced with FactoryGirl.
  config.include ShowMeTheCookies

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explictly tag your specs with their type, e.g.:
  #
  #     describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/v/3-0/docs
  config.infer_spec_type_from_file_location!


  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    # be_bigger_than(2).and_smaller_than(4).description
    #   # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #   # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end



  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
    ActionMailer::Base.deliveries.clear
    Timecop.return
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

if ENV['IN_BROWSER']
  # On demand: non-headless tests via Selenium/WebDriver
  # To run the scenarios in browser (default: Firefox), use the following command line:
  # IN_BROWSER=true bundle exec rspec
  # or (to have a pause of 1 second between each step):
  # IN_BROWSER=true PAUSE=1 bundle exec rspec
  Capybara.default_driver = :selenium
  # AfterStep do
  #   sleep (ENV['PAUSE'] || 0).to_i
  # end
else
  # DEFAULT: headless tests with poltergeist/PhantomJS
  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(
        app,
        window_size: [1280, 1024],
        timeout: 300,
        phantomjs_options: ['--ignore-ssl-errors=yes', '--ssl-protocol=any'], # http://phantomjs.org/api/command-line.html ie ['--debug=no', '--load-images=no', '--ignore-ssl-errors=yes', '--ssl-protocol=TLSv1']
        debug: false
    )
  end
  Capybara.default_driver    = :poltergeist
  Capybara.javascript_driver = :poltergeist
end

Capybara.default_wait_time = 5

Capybara.register_driver :rack_test do |app|
  Capybara::RackTest::Driver.new(app, :headers => { 'HTTP_USER_AGENT' => 'Capybara' })
end

def set_hidden_input_value(css_matcher, value)
  find(:css, css_matcher, :visible => false).set(value)
end

def fill_access_token_form(name, identifier, confirm_identifier=nil, is_public_computer=true, remember_me=false, return_path_with_access_token=true)
  confirm_identifier ||= identifier

  fill_in 'access_token_name', with: name
  fill_in 'access_token_identifier', with: identifier
  fill_in 'access_token_confirm_identifier', with: confirm_identifier

  if is_public_computer
    check('access_token_is_public')
  else
    uncheck('access_token_is_public')
  end

  if remember_me
    check('access_token_remember_me')
  else
    uncheck('access_token_remember_me')
  end
  click_button 'Request access token'

  if return_path_with_access_token
    expect(unread_emails_for(identifier).size).to eq(parse_email_count(1))
    e = open_last_email_for(identifier)
    return links_in_email(e).select {|url| /access_token/.match(url)}.first
  else
    return nil
  end
end

def fill_sign_in_form(email, password, is_public_computer=true, remember_me=false)
  fill_in 'sign_in_email', with: email
  fill_in 'sign_in_password', with: password

  if is_public_computer
    check('sign_in_is_public')
  else
    uncheck('sign_in_is_public')
  end

  if remember_me
    check('sign_in_remember_me')
  else
    uncheck('sign_in_remember_me')
  end
  click_button 'Sign In'
end

def fill_sign_up_form(email, password, password_confirmation=nil)
  password_confirmation ||= password
  fill_in 'sign_up_email', with: email
  fill_in 'sign_up_password', with: password
  fill_in 'sign_up_password_confirmation', with: password_confirmation
  click_button 'Sign Up'
end

def reload_page
  visit(current_path)
end

def reset_default_config
  DoorMat.configuration.password_reconfirm_delay = 5
  DoorMat.configuration.public_computer_access_session_timeout = 30
  DoorMat.configuration.private_computer_access_session_timeout = 60
  DoorMat.configuration.allow_remember_me_feature = false
  DoorMat.configuration.remember_me_require_private_computer_confirmation = true
  DoorMat.configuration.remember_me_max_day_count = 30
end


def test_only_session_guid_anywhere_regex
  /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/
end
