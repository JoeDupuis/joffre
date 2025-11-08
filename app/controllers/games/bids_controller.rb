module Games
  class BidsController < ApplicationController
    before_action :require_authentication
    before_action :set_game
    before_action :set_player

    def create
      @bid = @game.bids.build(
        player: @player,
        amount: bid_params[:amount].presence
      )

      if @bid.save
        handle_bid_success
      else
        redirect_to @game, alert: failure_message(@bid)
      end
    end

    private

    def set_game
      @game = Game.find(params[:game_id])
    end

    def set_player
      @player = @game.players.find_by(user: Current.user)
      unless @player
        redirect_to @game, alert: failure_message
      end
    end

    def bid_params
      params.require(:bid).permit(:amount)
    end

    def handle_bid_success
      flash[:notice] = success_message(@bid) if @game.reload.playing?
      redirect_to @game
    end
  end
end
