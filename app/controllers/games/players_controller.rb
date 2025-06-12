module Games
  class PlayersController < ApplicationController
    before_action :require_authentication

    def new
      @player = Player.new
    end

    def create
      @game = Game.find_by(game_code: player_params[:game_code]&.upcase)
      @player = Player.new(game: @game, user: Current.user, password: player_params[:password])

      if @player.save
        redirect_to @game, notice: success_message(@player)
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
