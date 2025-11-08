class Current < ActiveSupport::CurrentAttributes
  attribute :session, :game
  delegate :user, to: :session, allow_nil: true

  def player
    return unless game && user
    game.players.find_by(user: user)
  end
end
