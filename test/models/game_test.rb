require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "should not save game without name" do
    game = Game.new
    assert_not game.save
    assert_includes game.errors[:name], "can't be blank"
  end

  test "should save game with name" do
    game = Game.new(name: "Test Game")
    assert game.save
  end

  test "owner method returns the game owner" do
    user = users(:one)
    game = Game.create!(name: "Test Game")
    game.players.create!(user: user, owner: true)

    assert_equal user, game.owner
  end

  test "owner method returns nil when no owner" do
    game = Game.create!(name: "Test Game")
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

    # Dealer should be last
    assert_equal game.dealer, order.last

    # First bidder should be from opposite team
    dealer_team = game.dealer.team
    opposite_team = dealer_team == 1 ? 2 : 1
    assert_equal opposite_team, order.first.team
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

  test "all_passed? should return true when all 4 players pass" do
    game = games(:full_game)
    game.update!(status: :bidding)

    order = game.bidding_order

    # Disable validations to test the logic independently
    Bid.skip_callback(:create, :after, :check_bidding_completion)
    order.each do |player|
      Bid.create!(player: player, game: game, amount: nil)
    end
    Bid.set_callback(:create, :after, :check_bidding_completion)

    assert game.all_passed?
  end

  test "all_passed? should return false when at least one bid" do
    game = games(:full_game)
    game.update!(status: :bidding)

    order = game.bidding_order

    # Disable validations to test the logic independently
    Bid.skip_callback(:create, :after, :check_bidding_completion)
    Bid.create!(player: order[0], game: game, amount: 7)
    order[1..3].each do |player|
      Bid.create!(player: player, game: game, amount: nil)
    end
    Bid.set_callback(:create, :after, :check_bidding_completion)

    assert_not game.all_passed?
  end

  test "bidding_complete? should return true after a bid and 3 passes" do
    game = games(:full_game)
    game.update!(status: :bidding)

    order = game.bidding_order
    game.bids.create!(player: order[0], amount: 7)
    game.bids.create!(player: order[1], amount: nil)
    game.bids.create!(player: order[2], amount: nil)
    game.bids.create!(player: order[3], amount: nil)

    assert game.bidding_complete?
  end

  test "bidding_complete? should return false with less than 4 bids" do
    game = games(:full_game)
    game.update!(status: :bidding)

    order = game.bidding_order
    game.bids.create!(player: order[0], amount: 7)
    game.bids.create!(player: order[1], amount: nil)

    assert_not game.bidding_complete?
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
end
