class Game < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :users, through: :players

  validates :name, presence: true

  def owner
    players.owner.first&.user
  end
end
