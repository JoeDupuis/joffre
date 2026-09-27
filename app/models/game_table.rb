class GameTable
  Seat = Struct.new(:player, :position, keyword_init: true)

  POSITIONS = { 1 => :left, 2 => :partner, 3 => :right }.freeze
  TRICK_SLOTS = { left: "W", partner: "N", right: "E", you: "S" }.freeze
  TRICKS_PER_HAND = 8
  MAX_BID = 12

  attr_reader :game, :you

  def initialize(game, you)
    @game = game
    @you = you
  end

  def seats
    @seats ||= begin
      order = game.ordered_players
      index = order.index(you)
      POSITIONS.map { |offset, position| Seat.new(player: order[(index + offset) % 4], position:) }
    end
  end

  def player_at(position)
    return you if position == :you

    seats.find { |seat| seat.position == position }&.player
  end

  def position_of(player)
    return :you if player == you

    seats.find { |seat| seat.player == player }&.position
  end

  def us
    you.team
  end

  def them
    us == 1 ? 2 : 1
  end

  def teammate?(player)
    player.team == us
  end

  def score(team)
    game.team_total_score(team)
  end

  def hand_number
    game.current_round_number
  end

  def active_player
    return game.current_bidder if game.bidding?

    game.active_player if game.playing?
  end

  def your_turn?
    active_player == you
  end

  def hand
    @hand ||= you.cards.in_hand.order(:suite, :rank).to_a
  end

  def playable_card_ids
    @playable_card_ids ||= your_turn? && game.playing? ? you.playable_cards.pluck(:id).to_set : Set.new
  end

  def cards_left(player)
    player.cards.in_hand.count
  end

  def high_bid
    @high_bid ||= game.highest_bid
  end

  def bid_for(player)
    bids_by_player[player.id]
  end

  def bid_options
    minimum = high_bid ? high_bid.amount + 1 : game.minimum_bid
    (minimum..MAX_BID).to_a
  end

  def can_pass?
    !(game.dealer_must_bid? && you.dealer? && high_bid.nil?)
  end

  def trump
    @trump ||= game.trump_suit if game.playing?
  end

  def current_trick_cards
    @current_trick_cards ||= game.current_trick.cards.order(:trick_sequence).to_a
  end

  def last_trick
    return @last_trick if defined?(@last_trick)

    @last_trick = game.last_completed_trick if game.playing? && current_trick_cards.empty?
  end

  def trick_cards_by_position
    cards = last_trick ? last_trick.cards.order(:trick_sequence).to_a : current_trick_cards
    cards.index_by { |card| position_of(card.player) }
  end

  def trick_number
    game.tricks.where(completed: true).count + 1
  end

  def led_suit
    current_trick_cards.first&.suite
  end

  def last_round
    @last_round ||= game.last_round_summary
  end

  def show_last_round?
    game.bidding? && last_round&.bid_known?
  end

  def winning_team
    game.winning_team
  end

  private

  def bids_by_player
    @bids_by_player ||= game.bids.index_by(&:player_id)
  end
end
