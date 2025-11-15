module Games
  class PlaysController < ApplicationController
    include GameScoped

    before_action :require_authentication
    before_action :require_player

    def create
      card = Current.player.cards.find(play_params[:card_id])

      begin
        @game.play_card!(card)
        redirect_to @game, notice: success_message(card)
      rescue ArgumentError => e
        redirect_to @game, alert: e.message
      end
    end

    private

    def require_player
      unless Current.player
        redirect_to @game, alert: failure_message
      end
    end

    def play_params
      params.require(:play).permit(:card_id)
    end
  end
end
