ActiveRecord::Base.logger = nil

module Playtest
  PASSWORD = "Xk9#mP7$qR2@".freeze
  USERS = [
    { name: "Alice Johnson", email: "alice@example.com" },
    { name: "Bob Smith", email: "bob@example.com" },
    { name: "Carol Davis", email: "carol@example.com" },
    { name: "David Wilson", email: "david@example.com" }
  ].freeze
  STATES = %w[lobby bidding mid_trick trick_done round2 near_win done].freeze
  BASE_URL = ENV.fetch("PLAYTEST_URL", "http://localhost:3000")

  class InvariantError < StandardError; end

  module_function

  def users
    USERS.map do |attrs|
      User.find_or_create_by!(email_address: attrs[:email]) do |user|
        user.name = attrs[:name]
        user.password = PASSWORD
      end
    end
  end

  def create_lobby(name: "Playtest #{Time.current.strftime('%H:%M:%S')}", **settings)
    owner, *others = users
    game = Game.new(name:, **settings)
    game.players.build(user: owner, owner: true, dealer: true)
    game.save!
    others.each { |user| Player.create!(game:, user:) }
    game.id
  end

  def start(game_id)
    Game.find(game_id).update!(status: :bidding)
  end

  def bid_amount(game, bidder, bid_chance)
    forced = game.dealer_must_bid? && bidder == game.dealer && game.highest_bid.nil?
    return game.minimum_bid if forced
    return nil if game.highest_bid
    rand < bid_chance ? game.minimum_bid : nil
  end

  def bid!(game_id, bid_chance: 0.3)
    game = Game.find(game_id)
    bidder = game.current_bidder
    bid = game.place_bid!(player: bidder, amount: bid_amount(game, bidder, bid_chance))
    raise InvariantError, "Bid rejected: #{bid.errors.full_messages.to_sentence}" if bid.errors.any?
    bid
  end

  def play!(game_id, pick: :random)
    game = Game.find(game_id)
    cards = game.active_player.playable_cards.to_a
    raise InvariantError, "Active player has no playable card" if cards.empty?
    game.play_card!(pick == :first ? cards.first : cards.sample)
  end

  def step!(game_id, **options)
    game = Game.find(game_id)
    if game.bidding?
      bid!(game_id, **options.slice(:bid_chance))
    elsif game.playing?
      play!(game_id, **options.slice(:pick))
    else
      raise InvariantError, "Cannot step a #{game.status} game"
    end
  end

  def advance_until(game_id, limit: 50_000, **options)
    limit.times do
      return Game.find(game_id) if yield(Game.find(game_id))
      step!(game_id, **options)
    end
    raise InvariantError, "Game #{game_id} did not reach the requested state in #{limit} steps"
  end

  def completed_tricks(game)
    game.tricks.where(completed: true).count
  end

  def cards_in_current_trick(game)
    game.tricks.find_by(completed: false)&.cards&.count.to_i
  end

  def last_card_of_round?(game)
    game.playing? && completed_tricks(game) == 7 && cards_in_current_trick(game) == 3
  end

  def finishes_game?(game_id)
    finished = false
    ActiveRecord::Base.transaction(requires_new: true) do
      play!(game_id)
      finished = Game.find(game_id).done?
      raise ActiveRecord::Rollback
    end
    finished
  end

  def build(state, **settings)
    raise ArgumentError, "Unknown state #{state}. Use one of: #{STATES.join(', ')}" unless STATES.include?(state)

    game_id = create_lobby(**settings)
    return Game.find(game_id) if state == "lobby"

    start(game_id)
    case state
    when "bidding"
      Game.find(game_id)
    when "mid_trick"
      advance_until(game_id) { |game| game.playing? && completed_tricks(game).zero? && cards_in_current_trick(game) == 2 }
    when "trick_done"
      advance_until(game_id) { |game| game.playing? && completed_tricks(game) == 1 && cards_in_current_trick(game) == 0 }
    when "round2"
      advance_until(game_id) { |game| game.bidding? && game.round_scores.any? && game.bids.none? }
    when "near_win", "done"
      game = advance_until(game_id) { |candidate| last_card_of_round?(candidate) && finishes_game?(game_id) }
      state == "done" ? advance_until(game_id, &:done?) : game
    end
  end

  def describe(game)
    game = Game.find(game.id)
    lines = [ "Game ##{game.id} \"#{game.name}\" status=#{game.status} round=#{game.current_round_number} " \
              "score=#{game.team_total_score(1)}-#{game.team_total_score(2)} target=#{game.max_score}" ]
    lines << "URL: #{BASE_URL}/games/#{game.id}"
    game.players.includes(:user).order(:order, :id).each do |player|
      roles = []
      roles << "dealer" if player.dealer?
      roles << "owner" if player.owner?
      roles << "to bid" if game.bidding? && game.current_bidder == player
      roles << "to play" if game.playing? && game.active_player == player
      lines << "  user_id=#{player.user_id} #{player.user.email_address} team=#{player.team} " \
               "hand=#{player.cards.in_hand.count} #{roles.join(', ')}".rstrip
    end
    lines.join("\n")
  end

  def as_json(game)
    game = Game.find(game.id)
    {
      id: game.id,
      name: game.name,
      status: game.status,
      max_score: game.max_score,
      url: "#{BASE_URL}/games/#{game.id}",
      players: game.players.includes(:user).order(:id).map do |player|
        { user_id: player.user_id, email: player.user.email_address, name: player.user.name, team: player.team, owner: player.owner? }
      end
    }
  end
end
