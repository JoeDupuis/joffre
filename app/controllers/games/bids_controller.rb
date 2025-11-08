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
        redirect_to @game, alert: @bid.errors.full_messages.join(", ")
      end
    end

    private

    def set_game
      @game = Game.find(params[:game_id])
    end

    def set_player
      @player = @game.players.find_by(user: Current.user)
      unless @player
        redirect_to @game, alert: "You are not a player in this game"
      end
    end

    def bid_params
      params.require(:bid).permit(:amount)
    end

    def handle_bid_success
      if @game.reload.bidding?
        redirect_to @game
      elsif @game.playing?
        redirect_to @game, notice: "Bidding complete! #{@game.highest_bid.player.user.name} won with a bid of #{@game.highest_bid.amount}"
      else
        redirect_to @game
      end
    end
  end
end
