class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :players, dependent: :destroy
  has_many :games, through: :players

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def owned_games
    games.joins(:players).where(players: { user_id: id, owner: true })
  end
end
