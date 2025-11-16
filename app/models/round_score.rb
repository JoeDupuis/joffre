class RoundScore < ApplicationRecord
  belongs_to :game

  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :team, presence: true, inclusion: { in: [ 1, 2 ] }
  validates :score, presence: true, numericality: { only_integer: true }
  validates :team, uniqueness: { scope: [ :game_id, :number ] }
end
