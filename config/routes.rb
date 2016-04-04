DoorMat::Engine.routes.draw do
  if DoorMat.configuration.define_door_mat_routes

    get '/sign_up' => 'sign_up#new', as: 'sign_up'
    post '/sign_up' => 'sign_up#create'

    get '/sign_in' => 'sign_in#new', as: 'sign_in'
    post '/sign_in' => 'sign_in#create'
    get '/sign_out' => 'sign_in#destroy', as: 'sign_out'

    post '/terminate_session/:guid' => 'sessions#terminate', as: 'terminate_session'
    get '/reconfirm_password' => 'reconfirm_password#new', as: 'reconfirm_password'
    post '/reconfirm_password' => 'reconfirm_password#create'

    get '/add_email' => 'manage_email#new', as: 'add_email'
    post '/add_email' => 'manage_email#create'
    post '/delete_email' => 'manage_email#destroy'
    post '/set_primary_email' => 'manage_email#set_primary_email'

    get '/email_confirmation_required' => 'static#email_confirmation_required', as: 'email_confirmation_required'
    get '/confirm_email/:token/:email' => 'activities#confirm_email', as: 'confirm_email'
    post '/resend_email_confirmation' => 'activities#resend_email_confirmation', as: 'resend_email_confirmation'
    post '/download_recovery_key' => 'activities#download_recovery_key', as: 'download_recovery_key'

    get '/change_password' => 'change_password#new', as: 'change_password'
    post '/change_password' => 'change_password#create'

    get '/sign_up_success' => 'static#sign_up_success', as: 'sign_up_success'
    get '/sign_in_success' => 'static#sign_in_success', as: 'sign_in_success'
    get '/add_email_success' => 'static#add_email_success', as: 'add_email_success'
    get '/confirm_email_success' => 'static#confirm_email_success', as: 'confirm_email_success'
    get '/change_password_success' => 'static#change_password_success', as: 'change_password_success'
    get '/reconfirm_password_success' => 'static#reconfirm_password_success', as: 'reconfirm_password_success'


    # skip_before_filter :require_valid_session for these routes
    get '/access_token/:token_for(/:token)' => 'password_less_session#access_token', :as => 'access_token_token_for_token'
    post '/access_token' => 'password_less_session#access_token_post'

    get '/sign_out_success' => 'static#sign_out_success'
    get '/forgot_password_verification_mail_sent' => 'static#forgot_password_verification_mail_sent'

    get '/forgot_password' => 'forgot_passwords#new'
    post '/forgot_password' => 'forgot_passwords#create'
    get '/choose_new_password/:token/:email' => 'forgot_passwords#choose_new_password', as: 'choose_new_password'
    post '/reset_password' => 'forgot_passwords#reset_password', as: 'reset_password'
  end
end
