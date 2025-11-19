class GamesController < ApplicationController
  before_action :require_authentication
  before_action :set_game, only: [ :show, :update, :destroy ]

  def index
    @games = Current.user.games.includes(:players, :users)
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    @game.players.build(user: Current.user, owner: true, dealer: true)

    if @game.save
      redirect_to @game, notice: success_message(@game)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @game = Current.user.games.find(params[:id])
  end

  def update
    return head :not_found unless @game.players.exists?(user: Current.user, owner: true)

    if @game.update(update_game_params)
      redirect_to @game, notice: success_message(@game)
    else
      head :unprocessable_entity
    end
  end

  def destroy
    return head :not_found unless @game.players.exists?(user: Current.user, owner: true)
    return head :unprocessable_entity unless @game.pending?
    @game.destroy
    redirect_to games_path, notice: success_message(@game)
  end

  private

  def set_game
    Current.game = @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:name, :password, :password_confirmation, :all_players_pass_strategy)
  end

  def update_game_params
    params.require(:game).permit(:status)
  end
end
