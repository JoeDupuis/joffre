class Game < ApplicationRecord
  has_many :game_players, dependent: :destroy
  has_many :players, through: :game_players, source: :user

  validates :name, presence: true

  def owner
    game_players.find_by(owner: true)&.user
  end
end
