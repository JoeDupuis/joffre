require "optparse"
require_relative "playtest"

settings = {}
seed = nil
game_id = nil
json = false
OptionParser.new do |opts|
  opts.banner = "Usage: bin/rails runner script/playtest/state.rb STATE [options]\nStates: #{Playtest::STATES.join(', ')}, show"
  opts.on("--max-score N", Integer, "Target score (default 41)") { |value| settings[:max_score] = value }
  opts.on("--minimum-bid N", Integer, "Starting bid, 6 or 7") { |value| settings[:minimum_bid] = value }
  opts.on("--move-dealer", "Rotate the dealer when everyone passes") { settings[:all_players_pass_strategy] = :move_dealer }
  opts.on("--name NAME", "Game name") { |value| settings[:name] = value }
  opts.on("--game ID", Integer, "With the show state: describe an existing game") { |value| game_id = value }
  opts.on("--json", "Print JSON for script/playtest/browser.cjs") { json = true }
  opts.on("--seed N", Integer, "Random seed for deals and bots") { |value| seed = value }
end.parse!(ARGV)

srand(seed) if seed
game = ARGV.first == "show" ? Game.find(game_id) : Playtest.build(ARGV.first.to_s, **settings)
puts json ? Playtest.as_json(game).to_json : Playtest.describe(game)
