module GameScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_game
  end

  private

  def set_game
    Current.game = @game = Game.find(params[:game_id])
  end
end
