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
    @game = Game.find(params[:id])
  end

  def join
  end

  def perform_join
    @game = Game.find_by(game_code: params[:game_code]&.upcase)

    if @game.nil?
      flash.now[:alert] = "Invalid game code"
      render :join, status: :unprocessable_entity
      return
    end

    if @game.password_digest.present? && !@game.authenticate(params[:password])
      flash.now[:alert] = "Invalid password"
      render :join, status: :unprocessable_entity
      return
    end

    if @game.players.count >= 4
      flash.now[:alert] = "Game is full"
      render :join, status: :unprocessable_entity
      return
    end

    if @game.users.include?(Current.user)
      redirect_to @game, notice: "You are already in this game"
      return
    end

    @game.players.create!(user: Current.user)
    redirect_to @game, notice: success_message
  end

  private

  def game_params
    params.require(:game).permit(:name, :password, :password_confirmation)
  end
end
