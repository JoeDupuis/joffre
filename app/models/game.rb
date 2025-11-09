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
  has_many :tricks, dependent: :destroy

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

    cards.destroy_all
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

  def place_bid!(player:, amount:)
    bid = bids.build(player: player, amount: amount)

    if bid.save
      if all_players_passed?
        bids.destroy_all
        deal_cards!
      elsif bid_complete?
        update!(status: :playing)
      end
    end

    bid
  end

  def current_trick
    return nil unless playing?
    tricks.where(completed: false).first || tricks.create!
  end

  def play_order
    return [] unless playing? && players.count == 4

    ordered_players = players.order(:order).to_a

    starting_player = if first_trick?
                        then
                        highest_bid.player
                      else
                        last_trick_winner
                      end
    index = ordered_players.index(starting_player)
    ordered_players.rotate(index)
  end

  def first_trick?
    tricks.where(completed: true).empty?
  end

  def last_trick_winner
    tricks.where(completed: true).order(created_at: :desc).first.winner
  end

  def current_player_to_play
    return nil unless playing?

    order = play_order
    return nil if order.empty?

    cards_played = current_trick.cards.count
    return nil if cards_played >= 4

    order[cards_played]
  end

  def play_card!(player:, card:)
    raise ArgumentError, "Not this player's turn" unless current_player_to_play == player
    raise ArgumentError, "Card not in player's hand" unless card.player == player && card.trick_id.nil?

    trick = current_trick
    card.update!(trick: trick)

    if trick.complete?
      trick.complete_trick!
      check_round_complete!
    end

    card
  end

  def all_cards_played?
    cards.in_hand.count == 0
  end

  def check_round_complete!
    return unless all_cards_played?

    rotate_dealer!
    reset_for_bidding!
  end

  def rotate_dealer!
    current_dealer = dealer
    ordered_players = players.order(:order).to_a
    dealer_index = ordered_players.index(current_dealer)
    return unless dealer_index

    new_dealer_index = (dealer_index + 1) % 4
    new_dealer = ordered_players[new_dealer_index]

    current_dealer.update!(dealer: false)
    new_dealer.update!(dealer: true)
  end

  def reset_for_bidding!
    tricks.destroy_all
    bids.destroy_all
    update!(status: :bidding)
  end

  private

  def starting?
    will_save_change_to_status? && status == "bidding"
  end

  def just_started_bidding?
    saved_change_to_status? && status == "bidding"
  end

  def setup_bidding_phase!
    assign_player_orders!
    deal_cards!
  end

  def assign_player_orders!
    dealer_player = dealer
    dealer_player.update!(order: 1)

    opposite_team = dealer_player.team == 1 ? 2 : 1
    opposite_players = players.where(team: opposite_team).where.not(id: dealer_player.id).order(:id).to_a
    opposite_players[0].update!(order: 2)
    opposite_players[1].update!(order: 4)

    teammate = players.where(team: dealer_player.team).where.not(id: dealer_player.id).sole
    teammate.update!(order: 3)
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
