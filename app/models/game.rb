class Game < ApplicationRecord
  enum :status, { pending: 0, bidding: 1, playing: 2, done: 3 }
  has_secure_password validations: false
  validates :password, confirmation: true, if: -> { password.present? }

  validate :startable, if: :starting?
  after_update :setup_bidding_phase!, if: :just_started_bidding?

  has_many :players, dependent: :destroy
  has_many :users, through: :players
  has_many :cards, dependent: :destroy
  has_many :bids, dependent: :destroy

  validates :name, presence: true
  validates :game_code, presence: true, uniqueness: true

  before_validation :generate_game_code, on: :create

  def owner
    players.owner.first&.user
  end

  def dealer
    players.dealer.sole
  end

  def authenticate_for_join(password)
    return true unless password_digest.present?
    authenticate(password)
  end

  def deal_cards!
    raise ArgumentError, "Game must have exactly 4 players" unless players.count == 4

    deck = Card.deck
    player_list = players.to_a

    deck.each_with_index do |card_attrs, index|
      player = player_list[index % 4]
      cards.create!(card_attrs.merge(player: player))
    end
  end

  def bidding_order
    return [] unless players.count == 4

    ordered_players = players.order(:order).to_a
    dealer_index = ordered_players.index(dealer)
    return [] unless dealer_index

    ordered_players.rotate(dealer_index + 1)
  end

  def current_bidder
    order = bidding_order
    return nil if order.empty?

    bid_count = bids.count
    order[bid_count % 4]
  end

  def highest_bid
    bids.where.not(amount: nil).order(amount: :desc, created_at: :asc).first
  end

  def all_players_passed?
    bids.count == 4 && bids.where(amount: nil).count == 4
  end

  def bid_complete?
    (bids.count == 4 && highest_bid.present?) || highest_bid&.amount == 12
  end

  def reshuffle_and_rebid!
    cards.destroy_all
    bids.destroy_all
    deal_cards!
  end

  def place_bid!(player:, amount:)
    bid = bids.build(player: player, amount: amount)

    if bid.save
      if all_players_passed?
        reshuffle_and_rebid!
      elsif bid_complete?
        update!(status: :playing)
      end
    end

    bid
  end

  private

  def starting?
    will_save_change_to_status? && status == "bidding"
  end

  def just_started_bidding?
    saved_change_to_status? && status == "bidding"
  end

  def setup_bidding_phase!
    deal_cards!
  end

  def startable
    unless players.count == 4 && status_was == "pending"
      errors.add(:status, :invalid)
      return
    end

    unless players.all? { |p| p.team.present? }
      errors.add(:status, :teams_not_assigned)
      return
    end

    unless players.team_one.count == 2 && players.team_two.count == 2
      errors.add(:status, :teams_not_balanced)
    end
  end

  def generate_game_code
    self.game_code = loop do
      code = SecureRandom.alphanumeric(6).upcase
      break code unless Game.exists?(game_code: code)
    end
  end
end
