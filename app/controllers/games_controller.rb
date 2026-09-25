class GamesController < ApplicationController
  before_action :require_authentication
  before_action :set_game, only: [ :update, :destroy ]

  def index
    @games = Current.user.games.includes(:round_scores, players: :user).order(created_at: :desc)
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
    Current.game = @game = Current.user.games.find_by(id: params[:id])
    return if @game

    if Game.exists?(id: params[:id])
      redirect_to games_path, alert: t(".removed")
    else
      redirect_to games_path, alert: failure_message
    end
  end

  def update
    return head :not_found unless @game.players.exists?(user: Current.user, owner: true)
    return head :unprocessable_entity unless @game.pending? && update_game_params[:status] == "bidding"

    if @game.update(status: :bidding)
      redirect_to @game, notice: success_message(@game)
    else
      head :unprocessable_entity
    end
  end

  def destroy
    return head :not_found unless @game.players.exists?(user: Current.user, owner: true)
    @game.destroy
    redirect_to games_path, notice: success_message(@game)
  end

  private

  def set_game
    Current.game = @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:name, :password, :password_confirmation, :all_players_pass_strategy, :minimum_bid, :max_score)
  end

  def update_game_params
    params.require(:game).permit(:status)
  end
end
