module Games
  class BidsController < ApplicationController
    include GameScoped

    before_action :require_authentication
    before_action :require_player

    def create
      @bid = @game.place_bid!(
        player: Current.player,
        amount: bid_params[:amount].presence
      )

      if @bid.errors.empty?
        redirect_to @game
      else
        redirect_to @game, alert: failure_message(@bid)
      end
    end

    private

    def require_player
      unless Current.player
        redirect_to @game, alert: failure_message
      end
    end

    def bid_params
      params.require(:bid).permit(:amount)
    end
  end
end
