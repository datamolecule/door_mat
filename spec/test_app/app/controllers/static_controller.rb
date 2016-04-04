class StaticController < ApplicationController
  skip_before_action :require_valid_session, only: [:index]
  skip_before_action :require_confirmed_email, only: [:index, :session_protected_page]

  before_action :require_password_reconfirm, only: [:page_that_require_password_reconfirmation]
  before_action :update_session_last_activity_time, only: [:session_protected_page]
end
