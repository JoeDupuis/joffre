module Games
  class PlayersController < ApplicationController
    before_action :require_authentication

    def new
      @player = Player.new
    end

    def create
      @game = Game.find_by(game_code: player_params[:game_code]&.upcase)

      if @game.nil?
        @player = Player.new
        @player.errors.add(:base, "Invalid game code")
        render :new, status: :unprocessable_entity
        return
      end

      @player = @game.join_player(Current.user, player_params[:password])

      if @player.nil?
        @player = Player.new
        @player.errors.add(:base, "Invalid password")
        render :new, status: :unprocessable_entity
      elsif @player.persisted?
        redirect_to @game, notice: success_message
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def player_params
      params.require(:player).permit(:game_code, :password)
    end
  end
end
