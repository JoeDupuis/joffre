require "optparse"
require_relative "playtest"

games = 10
seed = Random.new_seed % 100_000
bid_chance = 0.3
max_rounds = 200
keep = false
settings = {}
OptionParser.new do |opts|
  opts.banner = "Usage: bin/rails runner script/playtest/simulate.rb [options]"
  opts.on("--games N", Integer, "Number of games (default #{games})") { |value| games = value }
  opts.on("--seed N", Integer, "Random seed") { |value| seed = value }
  opts.on("--bid-chance F", Float, "Chance an opening bidder bids the minimum (default #{bid_chance})") { |value| bid_chance = value }
  opts.on("--max-score N", Integer, "Target score (default 41)") { |value| settings[:max_score] = value }
  opts.on("--move-dealer", "Rotate the dealer when everyone passes") { settings[:all_players_pass_strategy] = :move_dealer }
  opts.on("--keep", "Keep the simulated games in the database instead of rolling them back") { keep = true }
  opts.on("--max-rounds N", Integer, "Fail a game that runs longer (default #{max_rounds})") { |value| max_rounds = value }
end.parse!(ARGV)

srand(seed)

def check!(condition, message)
  raise Playtest::InvariantError, message unless condition
end

def check_fresh_deal!(game)
  hands = game.players.map { |player| player.cards.in_hand.count }
  check!(hands == [ 8, 8, 8, 8 ], "Round #{game.current_round_number} dealt #{hands.inspect}")
  check!(game.cards.count == 32 && game.cards.played.none?, "Round #{game.current_round_number} deck has #{game.cards.count} cards, #{game.cards.played.count} played")
  check!(game.tricks.none?, "Round #{game.current_round_number} started with leftover tricks")
end

def check_round_scores!(game, number)
  rows = game.round_scores.where(number:).to_a
  check!(rows.size == 2, "Round #{number} has #{rows.size} score rows")
  taken = rows.sum(&:points_taken)
  check!(taken == 10, "Round #{number} points taken add up to #{taken}")
  rows.each do |row|
    expected = row.team == row.bidder.team && row.points_taken < row.bid_amount ? -row.bid_amount : row.points_taken
    check!(row.score == expected, "Round #{number} team #{row.team} scored #{row.score}, expected #{expected}")
  end
end

def check_finished!(game)
  scores = [ game.team_total_score(1), game.team_total_score(2) ]
  check!(game.done?, "Game ended in status #{game.status}")
  check!(scores.uniq.size == 2, "Game finished tied at #{scores.inspect}")
  winner = game.winning_team
  check!(winner.present?, "Finished game has no winner (#{scores.inspect})")
  check!(scores[winner - 1] == scores.max && scores.max >= game.max_score, "Winner #{winner} with #{scores.inspect} under target #{game.max_score}")
end

def simulate(settings, bid_chance, max_rounds)
  game_id = Playtest.create_lobby(**settings)
  Playtest.start(game_id)
  deals = 0
  rounds = 0

  loop do
    game = Game.find(game_id)
    break if game.done?

    if game.bidding? && game.bids.none?
      check_fresh_deal!(game)
      deals += 1
    end

    finished_round = game.current_round_number
    Playtest.step!(game_id, bid_chance:)
    game = Game.find(game_id)

    next unless game.current_round_number > finished_round

    check_round_scores!(game, finished_round)
    rounds += 1
    check!(rounds <= max_rounds, "Game #{game_id} still running after #{max_rounds} rounds")
  end

  game = Game.find(game_id)
  check_finished!(game)
  { id: game_id, rounds:, deals:, score: [ game.team_total_score(1), game.team_total_score(2) ] }
end

started = Time.current
results = games.times.map do |index|
  result = nil
  ActiveRecord::Base.transaction do
    result = simulate(settings, bid_chance, max_rounds)
    raise ActiveRecord::Rollback unless keep
  end
  puts format("game %3d  #%-5d rounds=%-3d deals=%-3d final=%d-%d", index + 1, result[:id], result[:rounds], result[:deals], *result[:score])
  result
rescue Playtest::InvariantError, ArgumentError, ActiveRecord::ActiveRecordError => error
  puts "game #{index + 1} FAILED: #{error.class}: #{error.message}"
  puts error.backtrace.grep(%r{app/}).first(5)
  nil
end

failures = results.count(&:nil?)
rounds = results.compact.sum { |result| result[:rounds] }
puts format("%d games, %d rounds, %d failures in %.1fs (seed %d)", games, rounds, failures, Time.current - started, seed)
exit(failures.zero? ? 0 : 1)
