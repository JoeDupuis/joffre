class GamesController < ApplicationController
  before_action :require_authentication

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)

    if @game.save
      @game.players.create!(user: Current.user, owner: true)
      redirect_to root_path, notice: "Game created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def game_params
    params.require(:game).permit(:name)
  end
end
