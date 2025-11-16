class Game < ApplicationRecord
  enum :status, { pending: 0, done: 1 }
  enum :all_players_pass_strategy, { move_dealer: 0, dealer_must_bid: 1 }
  has_secure_password validations: false
  validates :password, confirmation: true, if: -> { password.present? }

  validate :startable, if: :starting?
  after_update :setup_first_round!, if: :just_started?

  has_many :rounds, dependent: :destroy
  has_many :cards, dependent: :destroy
  has_many :players, dependent: :destroy
  has_many :users, through: :players

  validates :name, presence: true
  validates :game_code, presence: true, uniqueness: true

  before_validation :generate_game_code, on: :create

  def owner
    players.owner.first&.user
  end

  def dealer
    players.dealer.sole
  end

  def playing?
    current_round&.playing?
  end

  def bidding?
    current_round&.bidding?
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

    ordered_players(dealer).rotate(1)
  end

  def current_bidder
    order = bidding_order
    return nil if order.empty?
    return nil unless current_round

    bid_count = current_round.bids.count
    order[bid_count % 4]
  end

  def highest_bid
    current_round&.highest_bid
  end

  def place_bid!(player:, amount:)
    bid = current_round.bids.build(player: player, amount: amount)

    if bid.save
      if all_players_passed?
        handle_all_players_passed!
      elsif bid_complete?
        current_round.update!(status: :playing)
      end
    end

    bid
  end


  def next_round_sequence
    (rounds.maximum(:sequence) || 0) + 1
  end

  def current_round
    rounds.order(sequence: :desc).first
  end

  def handle_all_players_passed!
    rotate_dealer!
    current_round.update!(dealer: dealer)
    current_round.bids.destroy_all
    deal_cards!
  end

  def current_trick
    return nil unless current_round

    current_round.tricks.where(completed: false).first || current_round.tricks.create!(sequence: next_trick_sequence)
  end

  def next_trick_sequence
    return 1 unless current_round
    (current_round.tricks.maximum(:sequence) || 0) + 1
  end

  def play_order
    return [] unless players.count == 4
    return [] unless current_round&.playing?

    starting_player = if first_trick?
                        highest_bid.player
    else
                        last_trick_winner
    end
    ordered_players(starting_player)
  end

  def first_trick?
    current_round.tricks.where(completed: true).empty?
  end

  def last_trick_winner
    current_round.tricks.where(completed: true).order(sequence: :desc).first.winner
  end

  def trump_suit
    current_round.tricks.find_by(sequence: 1)&.led_suit
  end

  def active_player
    order = play_order
    return nil if order.empty?

    cards_played = current_trick.cards.count
    return nil if cards_played >= 4

    order[cards_played]
  end

  def play_card!(card)
    raise ArgumentError, "Not this player's turn" unless active_player == card.player
    raise ArgumentError, "Card not in player's hand" unless card.trick_id.nil?

    trick = current_trick

    if trick.led_suit.present? && trick.requires_following?(card.player)
      raise ArgumentError, "Must follow suit" unless card.suite == trick.led_suit
    end

    trick.add_card(card)

    check_round_complete!

    card
  end

  def all_cards_played?
    cards.reload.in_hand.count == 0
  end

  def check_round_complete!
    return unless all_cards_played?

    current_round.calculate_points!
    update_game_points!

    if game_won?
      update!(status: :done)
    else
      rotate_dealer!
      reset_for_bidding!
    end
  end

  def update_game_points!
    team_one_total = rounds.sum(:team_one_points)
    team_two_total = rounds.sum(:team_two_points)

    update!(team_one_points: team_one_total, team_two_points: team_two_total)
  end

  def game_won?
    team_one_points >= max_points || team_two_points >= max_points
  end

  def winning_team
    return nil unless done?
    return 1 if team_one_points >= max_points
    return 2 if team_two_points >= max_points
    nil
  end

  def started?
    rounds.exists?
  end

  def rotate_dealer!
    current_dealer = dealer
    new_dealer = ordered_players(current_dealer)[1]

    current_dealer.update!(dealer: false)
    new_dealer.update!(dealer: true)
  end

  def reset_for_bidding!
    start_new_round!
  end

  def start_new_round!
    rounds.create!(sequence: next_round_sequence, dealer: dealer, status: :bidding)
    deal_cards!
  end

  def ordered_players(first_player = nil)
    @ordered_players ||= players.order(:order).to_a
    return @ordered_players unless first_player.present?
    index = @ordered_players.index(first_player)
    @ordered_players.rotate(index)
  end

  private

  def all_players_passed?
    current_round.bids.count == 4 && current_round.bids.where(amount: nil).count == 4
  end

  def bid_complete?
    (current_round.bids.count == 4 && highest_bid.present?) || highest_bid&.amount == 12
  end

  def starting?
    rounds.empty? && players.count == 4
  end

  def just_started?
    saved_changes.present? && rounds.empty? && players.count == 4 && status == "pending"
  end

  def setup_first_round!
    return if rounds.any?

    assign_player_orders!
    start_new_round!
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
    unless players.count == 4
      errors.add(:base, :invalid)
      return
    end

    unless players.all? { |p| p.team.present? }
      errors.add(:base, :teams_not_assigned)
      return
    end

    unless players.team_one.count == 2 && players.team_two.count == 2
      errors.add(:base, :teams_not_balanced)
    end
  end

  def generate_game_code
    self.game_code = loop do
      code = SecureRandom.alphanumeric(6).upcase
      break code unless Game.exists?(game_code: code)
    end
  end
end
