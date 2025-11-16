require "test_helper"

class BidTest < ActiveSupport::TestCase
  test "valid bid" do
    game = games(:bidding_game)
    player = game.current_bidder

    bid = Bid.new(round: game.current_round, player: player, amount: 7)
    assert bid.valid?
  end

  test "valid pass" do
    game = games(:bidding_game)
    player = game.current_bidder

    bid = Bid.new(round: game.current_round, player: player, amount: nil)
    assert bid.valid?
  end

  test "invalid bid below minimum" do
    game = games(:bidding_game)
    player = game.current_bidder

    bid = Bid.new(round: game.current_round, player: player, amount: 5)
    assert_not bid.valid?
    assert_includes bid.errors[:amount], "must be greater than or equal to 6"
  end

  test "invalid bid above maximum" do
    game = games(:bidding_game)
    player = game.current_bidder

    bid = Bid.new(round: game.current_round, player: player, amount: 13)
    assert_not bid.valid?
    assert_includes bid.errors[:amount], "must be less than or equal to 12"
  end

  test "bid must be higher than current highest bid" do
    game = games(:bidding_game)
    order = game.bidding_order

    game.current_round.bids.create!(player: order[0], amount: 8)
    player = game.current_bidder

    bid = Bid.new(round: game.current_round, player: player, amount: 8)
    assert_not bid.valid?
    assert_includes bid.errors[:amount], "must be greater than or equal to 9"
  end

  test "player must be current bidder" do
    game = games(:bidding_game)
    wrong_player = game.players.where.not(id: game.current_bidder.id).first

    bid = Bid.new(round: game.current_round, player: wrong_player, amount: 7)
    assert_not bid.valid?
    assert_includes bid.errors[:player], "is invalid"
  end

  test "game must be in bidding phase" do
    game = games(:full_game)
    round = game.rounds.create!(sequence: 1, dealer: game.players.first, status: :playing)
    player = game.players.first

    bid = Bid.new(round: round, player: player, amount: 7)
    assert_not bid.valid?
    assert_includes bid.errors[:round], "is invalid"
  end

  test "requires round" do
    player = players(:full_game_player_one)
    bid = Bid.new(player: player, amount: 7)
    # Save without validation to avoid delegation error when round is nil
    bid.save(validate: false)
    bid = Bid.find(bid.id)

    # Now validate - it should fail on round_id presence
    assert_not bid.valid?
    assert_includes bid.errors[:round_id], "can't be blank"
  end

  test "requires player" do
    game = games(:bidding_game)
    bid = Bid.new(round: game.current_round, amount: 7)
    assert_not bid.valid?
    assert_includes bid.errors[:player_id], "can't be blank"
  end

  test "dealer cannot pass when dealer_must_bid strategy is set" do
    game = games(:bidding_game)
    order = game.bidding_order
    order[0..2].each do |player|
      game.current_round.bids.create!(player: player, amount: nil)
    end

    dealer = game.dealer
    assert_equal dealer, game.current_bidder

    bid = Bid.new(round: game.current_round, player: dealer, amount: nil)
    assert_not bid.valid?
    assert_includes bid.errors[:amount], "Dealer must bid"
  end

  test "dealer can pass when move_dealer strategy is set" do
    game = games(:bidding_game)
    game.update!(all_players_pass_strategy: :move_dealer)
    order = game.bidding_order
    order[0..2].each do |player|
      game.current_round.bids.create!(player: player, amount: nil)
    end

    dealer = game.dealer
    assert_equal dealer, game.current_bidder

    bid = Bid.new(round: game.current_round, player: dealer, amount: nil)
    assert bid.valid?
  end

  test "non-dealer can pass when dealer_must_bid strategy is set" do
    game = games(:bidding_game)
    player = game.current_bidder
    assert_not_equal player, game.dealer

    bid = Bid.new(round: game.current_round, player: player, amount: nil)
    assert bid.valid?
  end

  test "dealer can pass when dealer_must_bid strategy is set if another player has bid" do
    game = games(:bidding_game)
    order = game.bidding_order

    # First player bids
    game.current_round.bids.create!(player: order[0], amount: 7)
    # Second and third players pass
    game.current_round.bids.create!(player: order[1], amount: nil)
    game.current_round.bids.create!(player: order[2], amount: nil)

    dealer = game.dealer
    assert_equal dealer, game.current_bidder

    # Dealer should be able to pass since someone has already bid
    bid = Bid.new(round: game.current_round, player: dealer, amount: nil)
    assert bid.valid?
  end
end
