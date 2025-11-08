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
  belongs_to :dealer, class_name: "Player", optional: true

  validates :name, presence: true
  validates :game_code, presence: true, uniqueness: true

  before_validation :generate_game_code, on: :create

  def owner
    players.owner.first&.user
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

  # Returns array of players in bidding order
  def bidding_order
    return [] unless players.count == 4

    dealer_player = dealer || players.owner.first
    dealer_team = dealer_player.team
    opposite_team = dealer_team == 1 ? 2 : 1

    # Get players by team, sorted by ID
    opposite_players = players.where(team: opposite_team).order(:id).to_a
    dealer_team_players = players.where(team: dealer_team).order(:id).to_a

    # Remove dealer from their team's players
    dealer_team_players.delete(dealer_player)

    # Order: opposite team player 1, dealer team player, opposite team player 2, dealer
    [
      opposite_players[0],
      dealer_team_players[0],
      opposite_players[1],
      dealer_player
    ].compact
  end

  # Returns the player whose turn it is to bid
  def current_bidder
    order = bidding_order
    return nil if order.empty?

    bid_count = bids.count
    order[bid_count % 4]
  end

  # Returns the highest bid (or nil if no bids or only passes)
  def highest_bid
    bids.where.not(amount: nil).order(amount: :desc, created_at: :asc).first
  end

  # Check if all 4 players passed
  def all_players_passed?
    bids.count == 4 && bids.where(amount: nil).count == 4
  end

  # Check if bidding is complete (each player gets one turn or someone bid 12)
  def bid_complete?
    (bids.count == 4 && highest_bid.present?) || highest_bid&.amount == 12
  end

  # Reshuffle when everyone passes
  def reshuffle_and_rebid!
    cards.destroy_all
    bids.destroy_all
    deal_cards!
  end

  # Transition to playing phase
  def start_playing_phase!
    update!(status: :playing)
  end

  private

  def starting?
    will_save_change_to_status? && status == "bidding"
  end

  def just_started_bidding?
    saved_change_to_status? && status == "bidding"
  end

  def setup_bidding_phase!
    # Set dealer to owner for first round
    update_column(:dealer_id, players.owner.first.id) unless dealer
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
