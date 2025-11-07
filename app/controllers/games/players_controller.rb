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

    def update
      @player = Player.find(params[:id])

      unless @player.game.owner == Current.user
        head :forbidden
        return
      end

      if @player.game.started?
        head :unprocessable_entity
        return
      end

      if @player.update(update_player_params)
        redirect_to @player.game, notice: "Team assignment updated"
      else
        head :unprocessable_entity
      end
    end

    def destroy
      @player = Player.find(params[:id])

      if @player.game.started?
        head :unprocessable_entity
        return
      end

      if @player.user == Current.user
        @player.destroy
        redirect_to games_path, notice: success_message(@player)
      elsif @player.game.owner == Current.user
        game = @player.game
        @player.destroy
        redirect_to game_path(game), notice: success_message(@player)
      else
        head :not_found
      end
    end

    private

    def player_params
      params.require(:player).permit(:game_code, :password)
    end

    def update_player_params
      params.require(:player).permit(:team)
    end
  end
end
