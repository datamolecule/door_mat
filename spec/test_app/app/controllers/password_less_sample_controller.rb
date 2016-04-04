class PasswordLessSampleController < ApplicationController

  skip_before_action :require_valid_session
  skip_before_action :require_confirmed_email
  before_action -> {protected_by_password_less_session([:big_ticket, :multipass])}, only: [:draw_results, :play_game, :choose_door_post]
  before_action -> {protected_by_password_less_session(:play_game)}, only: [:show_loosing_door, :final_choice_post]
  before_action -> {protected_by_password_less_session(:show_loosing_door)}, only: [:final_result]
  before_action :update_session_last_activity_time

  def play_game
    access_token = DoorMat::AccessToken.current_access_token

    actor = DoorMat::Process::CreateNewAnonymousActor.owned_by(access_token.actor)
    @game = Game.init_for_actor_and_doors(actor, 10)
    @game.save!
    access_token.reference_id = @game.id
    access_token.save!

  rescue Exception => e
    DoorMat.configuration.logger.error "ERROR: Failed to save game? - #{e}"
  end

  def choose_door_post
    access_token = DoorMat::AccessToken.current_access_token
    @game = Game.find(access_token.reference_id)
    @game.player_select_door! params[:door].to_i
    @game.host_select_loosing_door
    @game.save!

    DoorMat::AccessToken.swap_token!(cookies, [:big_ticket, :multipass], :play_game)
    redirect_to show_loosing_door_url
  end

  def show_loosing_door
    access_token = DoorMat::AccessToken.current_access_token
    @game = Game.find(access_token.reference_id)
  end

  def final_choice_post
    access_token = DoorMat::AccessToken.current_access_token
    @game = Game.find(access_token.reference_id)
    @game.player_select_door! params[:door].to_i
    @game.save!

    DoorMat::AccessToken.swap_token!(cookies, :play_game, :show_loosing_door)
    redirect_to final_result_url
  end

  def final_result
    access_token = DoorMat::AccessToken.current_access_token
    @game = Game.find(access_token.reference_id)

    access_token.destroy!
  end

end
