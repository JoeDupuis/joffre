class Bid < ApplicationRecord
  belongs_to :game
  belongs_to :player

  validates :player_id, presence: true
  validates :game_id, presence: true
  validates :amount,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: :minimum_valid_amount,
      less_than_or_equal_to: 12
    },
    allow_nil: true
  validate :player_is_current_bidder, on: :create
  validate :game_is_in_bidding_phase, on: :create

  after_create :check_bidding_completion

  private

  def minimum_valid_amount
    game.highest_bid&.amount&.+(1) || game.minimum_bid
  end

  def player_is_current_bidder
    return unless game

    current_bidder = game.current_bidder
    unless current_bidder == player
      errors.add(:player, "it's not your turn to bid")
    end
  end

  def game_is_in_bidding_phase
    return unless game

    unless game.bidding?
      errors.add(:game, :invalid)
    end
  end

  def check_bidding_completion
    if game.all_passed?
      game.reshuffle_and_rebid!
    elsif game.bidding_complete?
      game.start_playing_phase!
    end
  end
end
