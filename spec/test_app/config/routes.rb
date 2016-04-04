Rails.application.routes.draw do

  get '/account/show' => 'account#show', as: 'account_show'
  patch '/account/update' => 'account#update'
  post '/account/update' => 'account#update'

  get '/session_protected_page' => 'static#session_protected_page', as: 'session_protected_page'
  get '/page_that_require_password_reconfirmation' => 'static#page_that_require_password_reconfirmation', as: 'page_that_require_password_reconfirmation'
  get '/only_confirmed_email_allowed' => 'static#only_confirmed_email_allowed', as: 'only_confirmed_email_allowed'


  # Password less session :big_ticket
  get '/draw_results' => 'password_less_sample#draw_results'
  # setup a game w 10 doors, randomly assign a winning door, linked to the current password less session and owned by anonymous actor
  # the player then choose one of the doors
  get '/play_game' => 'password_less_sample#play_game'
  # Record the player's choice and swap ticket to prevent user from going back to the previous step
  post '/choose_door' => 'password_less_sample#choose_door_post'

  # Password less session :play_game
  # Host open a loosing door and player has last opportunity to change door selection
  get '/show_loosing_door' => 'password_less_sample#show_loosing_door'
  # ticket swap
  post '/final_choice' => 'password_less_sample#final_choice_post'

  # Password less session :show_loosing_door
  get '/final_result' => 'password_less_sample#final_result'


  mount DoorMat::Engine => "/", as: "door_mat"

  # Anybody can get a ticket here to play the game
  get '/big_ticket' => 'door_mat/password_less_session#new', defaults: { token_for: :big_ticket }
  post '/big_ticket' => 'door_mat/password_less_session#create', defaults: { token_for: :big_ticket }

  # But only Leeloo can get a multipass
  get '/multipass' => 'door_mat/password_less_session#new', defaults: { token_for: :multipass }
  post '/multipass' => 'door_mat/password_less_session#create', defaults: { token_for: :multipass }

  root 'static#index'

end
