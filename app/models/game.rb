class Game < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :users, through: :players

  validates :name, presence: true

  def owner
    players.find_by(owner: true)&.user
  end
end
