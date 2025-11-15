class Trick < ApplicationRecord
  belongs_to :game
  belongs_to :winner, class_name: "Player", optional: true
  has_many :cards, -> { order(:id) }, dependent: :nullify

  validates :sequence, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 8 }
  validates :sequence, uniqueness: { scope: :game_id }

  def add_card(card)
    self.cards << card
    complete_trick! if cards.count == 4
  end

  def complete?
    cards.count == 4
  end

  private

  def complete_trick!
    return if completed?

    winning_card = calculate_winning_card
    update!(winner: winning_card.player, completed: true)
  end

  def calculate_winning_card
    return nil if cards.empty?

    lead_suit = cards.first.suite
    trump_suit = game.trump_suit

    winning_card = cards.first

    cards.each do |card|
      winning_card = card if card_beats?(card, winning_card, lead_suit, trump_suit)
    end

    winning_card
  end

  def card_beats?(challenger, current_winner, lead_suit, trump_suit)
    challenger_is_trump = challenger.suite == trump_suit
    winner_is_trump = current_winner.suite == trump_suit

    if challenger_is_trump && !winner_is_trump
      true
    elsif !challenger_is_trump && winner_is_trump
      false
    elsif challenger_is_trump && winner_is_trump
      challenger.rank > current_winner.rank
    elsif challenger.suite == lead_suit && current_winner.suite == lead_suit
      challenger.rank > current_winner.rank
    elsif challenger.suite == lead_suit && current_winner.suite != lead_suit
      true
    else
      false
    end
  end
end
