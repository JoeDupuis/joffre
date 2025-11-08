class Bid < ApplicationRecord
  belongs_to :game
  belongs_to :player

  validates :player_id, presence: true
  validates :game_id, presence: true
  validate :valid_bid_amount
  validate :player_is_current_bidder, on: :create
  validate :game_is_in_bidding_phase, on: :create

  after_create :check_bidding_completion

  private

  def valid_bid_amount
    return if amount.nil? # nil is valid (pass)

    unless amount.is_a?(Integer) && amount >= game.minimum_bid && amount <= 12
      errors.add(:amount, "must be between #{game.minimum_bid} and 12")
      return
    end

    highest = game.highest_bid
    if highest && amount <= highest.amount
      errors.add(:amount, "must be higher than current bid of #{highest.amount}")
    end
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
      errors.add(:game, "is not in bidding phase")
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
