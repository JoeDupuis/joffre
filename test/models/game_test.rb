require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "should not save game without name" do
    game = Game.new
    assert_not game.save
    assert_includes game.errors[:name], "can't be blank"
  end

  test "should save game with name" do
    game = Game.new(name: "Test Game")
    game.players.build(user: users(:one), owner: true, dealer: true)
    assert game.save
  end

  test "owner method returns the game owner" do
    user = users(:one)
    game = Game.new(name: "Test Game")
    game.players.build(user: user, owner: true, dealer: true)
    game.save!

    assert_equal user, game.owner
  end

  test "owner method returns nil when no owner" do
    game = Game.new(name: "Test Game")
    game.players.build(user: users(:one), owner: false, dealer: true)
    game.save!
    assert_nil game.owner
  end

  test "deal_cards! should create 32 cards" do
    game = games(:full_game)

    assert_difference "Card.count", 32 do
      game.deal_cards!
    end
  end

  test "deal_cards! should deal 8 cards to each player" do
    game = games(:full_game)

    game.deal_cards!

    game.players.each do |player|
      assert_equal 8, player.cards.count
    end
  end

  test "deal_cards! should create all combinations of suites and ranks" do
    game = games(:full_game)

    game.deal_cards!

    Card.suites.each_key do |suite|
      (0..7).each do |rank|
        assert game.cards.exists?(suite: suite, rank: rank), "Missing card: #{suite} #{rank}"
      end
    end
  end

  test "deal_cards! should raise error if game does not have 4 players" do
    game = games(:one)

    assert_raises(ArgumentError, "Game must have exactly 4 players") do
      game.deal_cards!
    end
  end

  test "starting bidding phase should automatically deal cards" do
    game = games(:full_game)

    assert_difference "Card.count", 32 do
      game.update!(status: :bidding)
    end

    assert_equal 32, game.cards.count
    game.players.each do |player|
      assert_equal 8, player.cards.count
    end
  end

  test "bidding_order should return players in correct order" do
    game = games(:full_game)
    game.update!(status: :bidding)

    order = game.bidding_order
    assert_equal 4, order.length

    dealer = game.dealer
    assert_equal dealer, order.last

    ordered_players = game.players.order(:order).to_a
    dealer_index = ordered_players.index(dealer)
    expected_order = ordered_players.rotate(dealer_index + 1)
    assert_equal expected_order, order
  end

  test "current_bidder should return first player when no bids" do
    game = games(:full_game)
    game.update!(status: :bidding)

    assert_equal game.bidding_order.first, game.current_bidder
  end

  test "current_bidder should cycle through players" do
    game = games(:full_game)
    game.update!(status: :bidding)

    order = game.bidding_order

    # After 0 bids, should be first player
    assert_equal order[0], game.current_bidder

    # After 1 bid, should be second player
    game.bids.create!(player: order[0], amount: 7)
    assert_equal order[1], game.current_bidder

    # After 2 bids, should be third player
    game.bids.create!(player: order[1], amount: nil)
    assert_equal order[2], game.current_bidder
  end

  test "highest_bid should return the bid with highest amount" do
    game = games(:full_game)
    game.update!(status: :bidding)

    order = game.bidding_order
    game.bids.create!(player: order[0], amount: 7)
    game.bids.create!(player: order[1], amount: 8)
    highest = game.bids.create!(player: order[2], amount: 9)

    assert_equal highest, game.highest_bid
  end

  test "highest_bid should ignore passes" do
    game = games(:full_game)
    game.update!(status: :bidding)

    order = game.bidding_order
    highest = game.bids.create!(player: order[0], amount: 7)
    game.bids.create!(player: order[1], amount: nil)
    game.bids.create!(player: order[2], amount: nil)

    assert_equal highest, game.highest_bid
  end

  test "bidding order changes when dealer changes" do
    game = games(:full_game)
    game.update!(status: :bidding)

    original_dealer = game.dealer
    original_order = game.bidding_order

    # Change dealer to next player in order
    next_dealer = original_order[1]
    original_dealer.update!(dealer: false)
    next_dealer.update!(dealer: true)
    game.reload

    new_order = game.bidding_order

    # New order should start after new dealer
    assert_equal next_dealer, new_order.last
    assert_not_equal original_order, new_order
  end

  test "with move_dealer strategy, all players passing should rotate dealer and reshuffle" do
    game = games(:full_game)
    game.update!(status: :bidding, all_players_pass_strategy: :move_dealer)

    original_dealer = game.dealer
    order = game.bidding_order

    order.each do |player|
      game.place_bid!(player: player, amount: nil)
    end

    game.reload
    assert_equal 0, game.bids.count
    assert_not_equal original_dealer, game.dealer
    assert_equal 32, game.cards.count
    assert game.bidding?
  end

  test "max_score defaults to 41" do
    game = Game.create!(name: "Test Game")
    game.players.build(user: users(:one), owner: true, dealer: true)
    game.save!

    assert_equal 41, game.max_score
  end

  test "current_round_number starts at 1" do
    game = games(:full_game)
    assert_equal 1, game.current_round_number
  end

  test "current_round_number increments after round scores" do
    game = games(:full_game)
    game.round_scores.create!(number: 1, team: 1, score: 10)
    game.round_scores.create!(number: 1, team: 2, score: 5)

    assert_equal 2, game.current_round_number
  end

  test "team_total_score sums all round scores for a team" do
    game = games(:full_game)
    game.round_scores.create!(number: 1, team: 1, score: 10)
    game.round_scores.create!(number: 2, team: 1, score: 15)
    game.round_scores.create!(number: 1, team: 2, score: 5)

    assert_equal 25, game.team_total_score(1)
    assert_equal 5, game.team_total_score(2)
  end

  test "game continues to bidding when no team reached max_score" do
    game = games(:playing_game)
    game.update!(max_score: 41, status: :playing)

    players_list = game.players.order(:order).to_a
    team_1_players = players_list.select { |p| p.team == 1 }
    team_2_players = players_list.select { |p| p.team == 2 }

    8.times do |i|
      trick = game.tricks.create!(sequence: i + 1, completed: true, value: 2, winner: team_1_players[0])
    end

    game.cards.update_all(trick_id: game.tricks.first.id)

    game.check_round_complete!
    game.reload

    assert game.bidding?
    assert_equal 16, game.team_total_score(1)
  end

  test "game status changes to done when team 1 reaches max_score" do
    game = games(:playing_game)
    game.update!(max_score: 41, status: :playing)

    players_list = game.players.order(:order).to_a
    team_1_players = players_list.select { |p| p.team == 1 }
    team_2_players = players_list.select { |p| p.team == 2 }

    8.times do |i|
      trick = game.tricks.create!(sequence: i + 1, completed: true, value: 6, winner: team_1_players[0])
    end

    game.cards.update_all(trick_id: game.tricks.first.id)

    game.check_round_complete!
    game.reload

    assert game.done?
    assert_equal 48, game.team_total_score(1)
  end

  test "game status changes to done when team 2 reaches max_score" do
    game = games(:playing_game)
    game.update!(max_score: 41, status: :playing)

    players_list = game.players.order(:order).to_a
    team_1_players = players_list.select { |p| p.team == 1 }
    team_2_players = players_list.select { |p| p.team == 2 }

    8.times do |i|
      trick = game.tricks.create!(sequence: i + 1, completed: true, value: 6, winner: team_2_players[0])
    end

    game.cards.update_all(trick_id: game.tricks.first.id)

    game.check_round_complete!
    game.reload

    assert game.done?
    assert_equal 48, game.team_total_score(2)
  end

  test "minimum_bid defaults to 6" do
    assert_equal 6, Game.new.minimum_bid
  end

  test "minimum_bid must be 6 or 7" do
    game = games(:one)

    game.minimum_bid = 7
    assert game.valid?

    [ 5, 8, nil ].each do |amount|
      game.minimum_bid = amount
      assert_not game.valid?, "expected minimum_bid #{amount.inspect} to be invalid"
      assert game.errors[:minimum_bid].any?
    end
  end

  test "max_score must be a positive integer" do
    game = games(:one)

    game.max_score = 40
    assert game.valid?

    [ 0, -5, 40.5, nil ].each do |score|
      game.max_score = score
      assert_not game.valid?, "expected max_score #{score.inspect} to be invalid"
      assert game.errors[:max_score].any?
    end
  end

  test "current_trick does not persist a trick when none is in progress" do
    game = games(:playing_game)

    assert_no_difference "Trick.count" do
      trick = game.current_trick
      assert trick.new_record?
      assert_equal 1, trick.sequence
      assert_empty trick.cards
    end
  end

  test "reading game state after a trick completes does not create the next trick" do
    game = games(:playing_game)
    4.times do
      game = Game.find(game.id)
      game.play_card!(game.active_player.playable_cards.first)
    end

    assert_no_difference "Trick.count" do
      4.times do
        game = Game.find(game.id)
        game.active_player
        game.current_trick
        game.players.each(&:playable_cards)
      end
    end
    assert_equal [ 1 ], game.tricks.pluck(:sequence)
  end

  test "a full round is led by the high bidder then each trick's winner with trump from the first lead" do
    game = games(:full_game)
    game.update!(status: :bidding)

    game = Game.find(game.id)
    game.place_bid!(player: game.current_bidder, amount: 7)
    3.times do
      game = Game.find(game.id)
      game.place_bid!(player: game.current_bidder, amount: nil)
    end
    game = Game.find(game.id)
    bidder = game.highest_bid.player
    assert_equal 0, game.tricks.count

    expected_leader = bidder
    8.times do |index|
      game = Game.find(game.id)
      assert_equal expected_leader, game.active_player
      assert_equal index, game.tricks.count

      4.times do
        game = Game.find(game.id)
        game.play_card!(game.current_trick.playable_cards(game.active_player).first)
      end

      game = Game.find(game.id)
      break if index == 7

      trick = game.last_completed_trick
      assert_equal index + 1, trick.sequence
      assert_equal 4, trick.cards.count
      assert_equal game.tricks.find_by(sequence: 1).cards.order(:trick_sequence).first.suite, game.trump_suit
      expected_leader = trick.winner
    end

    assert game.bidding?
    assert_equal 0, game.tricks.count
    assert_equal 2, game.round_scores.count
  end

  test "a full round of play re-deals fresh cards for the next round" do
    game = games(:full_game)
    game.update!(status: :bidding)
    original_card_ids = game.cards.pluck(:id)

    game = Game.find(game.id)
    game.place_bid!(player: game.current_bidder, amount: 7)
    3.times do
      game = Game.find(game.id)
      game.place_bid!(player: game.current_bidder, amount: nil)
    end
    assert Game.find(game.id).playing?

    32.times do
      game = Game.find(game.id)
      player = game.active_player
      game.play_card!(game.current_trick.playable_cards(player).first)
    end

    game = Game.find(game.id)
    assert game.bidding?
    assert_equal 2, game.round_scores.count
    assert_equal 0, game.bids.count
    assert_equal 0, game.tricks.count
    assert_equal 32, game.cards.count
    assert_empty game.cards.pluck(:id) & original_card_ids
    assert_equal 0, game.cards.where.not(trick_sequence: nil).count
    game.players.each do |player|
      assert_equal 8, player.cards.in_hand.count
    end
  end

  test "winning_team is nil when no team reached max_score" do
    game = games(:full_game)
    game.round_scores.create!(number: 1, team: 1, score: 40)
    game.round_scores.create!(number: 1, team: 2, score: 10)

    assert_nil game.winning_team
  end

  test "winning_team is the team that reached max_score" do
    game = games(:full_game)
    game.round_scores.create!(number: 1, team: 1, score: 10)
    game.round_scores.create!(number: 1, team: 2, score: 42)

    assert_equal 2, game.winning_team
  end

  test "winning_team is the higher score when both teams reach max_score" do
    game = games(:full_game)
    game.round_scores.create!(number: 1, team: 1, score: 45)
    game.round_scores.create!(number: 1, team: 2, score: 48)

    assert_equal 2, game.winning_team
  end

  test "winning_team is nil when both teams tie above max_score" do
    game = games(:full_game)
    game.round_scores.create!(number: 1, team: 1, score: 45)
    game.round_scores.create!(number: 1, team: 2, score: 45)

    assert_nil game.winning_team
  end

  test "game is won by the higher score when both teams cross max_score on the same hand" do
    game = games(:playing_game)
    game.round_scores.create!(number: 1, team: 1, score: 0)
    game.round_scores.create!(number: 1, team: 2, score: 50)
    team_1_player = game.players.find_by(team: 1)

    8.times do |i|
      game.tricks.create!(sequence: i + 1, completed: true, value: 6, winner: team_1_player)
    end
    game.cards.update_all(trick_id: game.tricks.first.id)

    game.check_round_complete!
    game.reload

    assert game.done?
    assert_equal 2, game.winning_team
  end

  test "another hand is played when both teams tie above max_score" do
    game = games(:playing_game)
    game.round_scores.create!(number: 1, team: 1, score: 0)
    game.round_scores.create!(number: 1, team: 2, score: 48)
    team_1_player = game.players.find_by(team: 1)

    8.times do |i|
      game.tricks.create!(sequence: i + 1, completed: true, value: 6, winner: team_1_player)
    end
    game.cards.update_all(trick_id: game.tricks.first.id)

    game.check_round_complete!
    game.reload

    assert game.bidding?
    assert_nil game.winning_team
    assert_equal 48, game.team_total_score(1)
    assert_equal 48, game.team_total_score(2)
  end

  test "team_round_points sums completed trick values won by a team" do
    game = games(:playing_game)
    team_1_player = players(:playing_game_player_one)
    team_2_player = players(:playing_game_player_two)

    game.tricks.create!(sequence: 1, completed: true, value: 6, winner: team_1_player)
    game.tricks.create!(sequence: 2, completed: true, value: -2, winner: team_2_player)
    game.tricks.create!(sequence: 3, completed: true, value: 1, winner: players(:playing_game_player_three))
    game.tricks.create!(sequence: 4, completed: false)

    assert_equal 7, game.team_round_points(1)
    assert_equal(-2, game.team_round_points(2))
  end

  test "last_completed_trick returns the most recent completed trick" do
    game = games(:playing_game)
    assert_nil game.last_completed_trick

    game.tricks.create!(sequence: 1, completed: true, value: 1, winner: players(:playing_game_player_one))
    second = game.tricks.create!(sequence: 2, completed: true, value: 1, winner: players(:playing_game_player_two))
    game.tricks.create!(sequence: 3, completed: false)

    assert_equal second, game.last_completed_trick
  end

  test "round scores record the bid, bidder and points taken when the bid is made" do
    game = games(:playing_game)
    bidder = players(:playing_game_player_one)

    8.times do |i|
      game.tricks.create!(sequence: i + 1, completed: true, value: 1, winner: bidder)
    end
    game.cards.update_all(trick_id: game.tricks.first.id)

    game.check_round_complete!

    bidding_row = game.round_scores.find_by(number: 1, team: 1)
    other_row = game.round_scores.find_by(number: 1, team: 2)
    assert_equal [ bidder, 8, 8, 8 ], [ bidding_row.bidder, bidding_row.bid_amount, bidding_row.points_taken, bidding_row.score ]
    assert_equal [ bidder, 8, 0, 0 ], [ other_row.bidder, other_row.bid_amount, other_row.points_taken, other_row.score ]

    summary = game.last_round_summary
    assert_equal 1, summary.number
    assert_equal bidder, summary.bidder
    assert_equal 1, summary.bidding_team
    assert summary.made?
  end

  test "round scores record points taken when the bidding team is set" do
    game = games(:playing_game)
    team_1_player = players(:playing_game_player_one)
    team_2_player = players(:playing_game_player_two)

    game.tricks.create!(sequence: 1, completed: true, value: 6, winner: team_1_player)
    7.times do |i|
      game.tricks.create!(sequence: i + 2, completed: true, value: 1, winner: team_2_player)
    end
    game.cards.update_all(trick_id: game.tricks.first.id)

    game.check_round_complete!

    summary = game.last_round_summary
    assert_not summary.made?
    assert_equal 6, summary.points_taken(1)
    assert_equal(-8, summary.score(1))
    assert_equal 7, summary.points_taken(2)
    assert_equal 7, summary.score(2)
  end

  test "round_summaries group rounds with running totals" do
    game = games(:playing_game)
    bidder = players(:playing_game_player_two)
    game.round_scores.create!(number: 1, team: 1, score: 3, points_taken: 3, bidder:, bid_amount: 7)
    game.round_scores.create!(number: 1, team: 2, score: 7, points_taken: 7, bidder:, bid_amount: 7)
    game.round_scores.create!(number: 2, team: 1, score: 5, points_taken: 5, bidder:, bid_amount: 8)
    game.round_scores.create!(number: 2, team: 2, score: -8, points_taken: 5, bidder:, bid_amount: 8)

    summaries = game.round_summaries

    assert_equal [ 1, 2 ], summaries.map(&:number)
    assert_equal [ 3, 7 ], [ summaries.first.total(1), summaries.first.total(2) ]
    assert_equal [ 8, -1 ], [ summaries.last.total(1), summaries.last.total(2) ]
    assert summaries.first.made?
    assert_not summaries.last.made?
  end

  test "round_summaries tolerate rounds recorded without bid details" do
    game = games(:playing_game)
    game.round_scores.create!(number: 1, team: 1, score: 4)
    game.round_scores.create!(number: 1, team: 2, score: 5)

    summary = game.last_round_summary

    assert_not summary.bid_known?
    assert_not summary.made?
    assert_equal 5, summary.total(2)
  end

  test "last_round_summary is nil before any round is scored" do
    assert_nil games(:playing_game).last_round_summary
  end
end
