class Trick < ApplicationRecord
  belongs_to :game
  belongs_to :winner, class_name: "Player", optional: true
  has_many :cards, dependent: :nullify

  validates :sequence, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 8 }
  validates :sequence, uniqueness: { scope: :game_id }

  def add_card(card)
    self.cards << card
    complete_trick!  cards.count == 4
  end

  def complete?
    cards.count == 4
  end

  private

  def complete_trick!
    return if completed?

    # TODO actually calculate the winner
    # temp hardcode the highest bid
    winner = game.highest_bid.player

    update!(winner:, completed: true)
  end
end
