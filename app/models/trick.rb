class Trick < ApplicationRecord
  belongs_to :game
  belongs_to :winner, class_name: "Player", optional: true
  has_many :cards, dependent: :nullify

  scope :completed, -> { where(completed: true) }

  validates :sequence, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 8 }
  validates :sequence, uniqueness: { scope: :game_id }

  def add_card(card)
    card.update!(trick: self)
    complete_trick! if cards.count == 4
  end

  def complete?
    cards.count == 4
  end

  def led_suit
    cards.order(:trick_sequence).first&.suite
  end

  def requires_following?(player)
    return false if led_suit.nil?
    player.cards.in_hand.exists?(suite: led_suit)
  end

  def playable_cards(player)
    return player.cards.in_hand if led_suit.nil?

    if requires_following?(player)
      player.cards.in_hand.where(suite: led_suit)
    else
      player.cards.in_hand
    end
  end

  private

  def complete_trick!
    return if completed?

    winner = calculate_winner
    update!(winner:, completed: true)
  end

  def calculate_winner
    return nil if cards.count < 4

    led_suit_value = led_suit
    winning_card = cards
      .where(suite: led_suit_value)
      .order(rank: :desc)
      .first

    winning_card.player
  end
end
