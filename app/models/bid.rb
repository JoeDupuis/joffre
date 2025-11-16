class Bid < ApplicationRecord
  belongs_to :round
  belongs_to :player

  delegate :game, to: :round

  validates :player_id, presence: true
  validates :round_id, presence: true
  validates :amount,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: :minimum_valid_amount,
      less_than_or_equal_to: 12
    },
    allow_nil: true
  validate :player_is_current_bidder, on: :create
  validate :round_is_in_bidding_phase, on: :create
  validate :dealer_cannot_pass_if_required, on: :create

  private

  def minimum_valid_amount
    return 0 unless round
    round.highest_bid&.amount&.+(1) || game.minimum_bid
  end

  def player_is_current_bidder
    return unless game

    unless game.current_bidder == player
      errors.add(:player, :invalid)
    end
  end

  def round_is_in_bidding_phase
    return unless round

    unless round.bidding?
      errors.add(:round, :invalid)
    end
  end

  def dealer_cannot_pass_if_required
    return unless game&.dealer_must_bid?
    return unless amount.nil?
    return unless player == game.dealer
    return if round.highest_bid.present?

    errors.add(:amount, :dealer_must_bid)
  end
end
