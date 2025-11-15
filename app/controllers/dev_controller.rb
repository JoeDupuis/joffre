class DevController < ApplicationController
  before_action :ensure_development_environment
  allow_unauthenticated_access only: %i[ switch_user ]

  def switch_user
    user = User.find(params[:user_id])
    game = Game.find(params[:game_id])

    terminate_session if authenticated?
    start_new_session_for(user)

    redirect_to game_path(game)
  end

  private

  def ensure_development_environment
    head :forbidden unless Rails.env.development?
  end
end
