class AccountController < ApplicationController
  before_action -> {require_password_reconfirm(15)} # override the default password_reconfirm_delay
  before_action :update_session_last_activity_time

  def show
    @actor = DoorMat::Session.current_session.actor

    if @actor.user_detail.blank?
      @actor.user_detail = UserDetail.new
    end
  end

  def update
    actor = DoorMat::Session.current_session.actor

    actor.user_detail.name = update_params[:name]
    actor.user_detail.save!

    redirect_to account_show_url
  end

  private

  def update_params
    params.require(:user_detail).permit(:name)
  end

end
