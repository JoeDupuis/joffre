class GamesController < ApplicationController
  before_action :require_authentication

  def index
    @games = Current.user.games.includes(:players, :users)
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)

    if @game.save
      @game.players.create!(user: Current.user, owner: true)
      redirect_to @game, notice: success_message(@game)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @game = Current.user.games.find(params[:id])
  end

  def update
    @game = Current.user.owned_games.find(params[:id])

    if @game.update(update_game_params)
      redirect_to @game, notice: success_message(@game)
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @game = Current.user.owned_games.find(params[:id])
    return head :unprocessable_entity if @game.started?
    @game.destroy
    redirect_to games_path, notice: success_message(@game)
  end

  private

  def game_params
    params.require(:game).permit(:name, :password, :password_confirmation)
  end

  def update_game_params
    params.require(:game).permit(:status)
  end
end
