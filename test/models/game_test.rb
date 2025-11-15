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
end
