class Trick < ApplicationRecord
  belongs_to :game
  belongs_to :winner, class_name: "Player", optional: true
  has_many :cards, dependent: :nullify

  def complete?
    cards.count == 4
  end

  def complete_trick!
    return unless complete? && !completed?

    update!(winner: game.highest_bid.player, completed: true)
  end
end
