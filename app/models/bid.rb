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
  validate :dealer_cannot_pass_if_required, on: :create

  private

  def minimum_valid_amount
    return 0 unless game
    game.highest_bid&.amount&.+(1) || game.minimum_bid
  end

  def player_is_current_bidder
    return unless game

    unless game.current_bidder == player
      errors.add(:player, :invalid)
    end
  end

  def game_is_in_bidding_phase
    return unless game

    unless game.bidding?
      errors.add(:game, :invalid)
    end
  end

  def dealer_cannot_pass_if_required
    return unless game&.dealer_must_bid?
    return unless amount.nil?
    return unless  player == game.dealer

    errors.add(:amount, :dealer_must_bid)
  end
end
