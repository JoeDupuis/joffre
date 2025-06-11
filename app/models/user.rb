class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :game_players, dependent: :destroy
  has_many :games, through: :game_players

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def owned_games
    games.joins(:game_players).where(game_players: { user_id: id, owner: true })
  end
end
