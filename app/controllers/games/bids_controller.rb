module Games
  class BidsController < ApplicationController
    before_action :require_authentication
    before_action :set_game
    before_action :set_current_player

    def create
      @bid = @game.place_bid!(
        player: Current.player,
        amount: bid_params[:amount].presence
      )

      if @bid.persisted?
        flash[:notice] = success_message(@bid) if @game.reload.playing?
        redirect_to @game
      else
        redirect_to @game, alert: failure_message(@bid)
      end
    end

    private

    def set_game
      @game = Game.find(params[:game_id])
    end

    def set_current_player
      Current.player = @game.players.find_by(user: Current.user)
      unless Current.player
        redirect_to @game, alert: failure_message
      end
    end

    def bid_params
      params.require(:bid).permit(:amount)
    end
  end
end
