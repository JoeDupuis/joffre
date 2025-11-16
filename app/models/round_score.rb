class RoundScore < ApplicationRecord
  belongs_to :game

  validates :number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :team, presence: true, inclusion: { in: [ 1, 2 ] }
  validates :score, presence: true, numericality: { only_integer: true }
  validates :number, uniqueness: { scope: [ :game_id, :team ] }
end
