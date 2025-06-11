class GamesController < ApplicationController
  before_action :require_authentication
  before_action :set_game, only: [ :show ]

  def new
    @game = Game.new
  end

  def show
  end

  def create
    @game = Game.new(game_params)

    if @game.save
      @game.players.create!(user: Current.user, owner: true)
      redirect_to root_path, notice: "Game created successfully! Game code: #{@game.game_code}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def join
    @game = Game.find_by(game_code: params[:game_code])

    if @game.nil?
      redirect_to root_path, alert: "Game not found with code: #{params[:game_code]}"
      return
    end

    if @game.password_protected? && !@game.authenticate_password(params[:password])
      redirect_to root_path, alert: "Invalid password for game"
      return
    end

    if @game.players.exists?(user: Current.user)
      redirect_to root_path, notice: "You're already in this game!"
      return
    end

    @game.players.create!(user: Current.user, owner: false)
    redirect_to root_path, notice: "Successfully joined game: #{@game.name}"
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:name, :password)
  end
end
