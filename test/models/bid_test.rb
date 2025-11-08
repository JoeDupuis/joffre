require "test_helper"

class BidTest < ActiveSupport::TestCase
  test "valid bid" do
    game = games(:full_game)
    game.update!(status: :bidding)
    player = game.current_bidder

    bid = Bid.new(game: game, player: player, amount: 7)
    assert bid.valid?
  end

  test "valid pass" do
    game = games(:full_game)
    game.update!(status: :bidding)
    player = game.current_bidder

    bid = Bid.new(game: game, player: player, amount: nil)
    assert bid.valid?
  end

  test "invalid bid below minimum" do
    game = games(:full_game)
    game.update!(status: :bidding)
    player = game.current_bidder

    bid = Bid.new(game: game, player: player, amount: 5)
    assert_not bid.valid?
    assert_includes bid.errors[:amount], "must be greater than or equal to 6"
  end

  test "invalid bid above maximum" do
    game = games(:full_game)
    game.update!(status: :bidding)
    player = game.current_bidder

    bid = Bid.new(game: game, player: player, amount: 13)
    assert_not bid.valid?
    assert_includes bid.errors[:amount], "must be less than or equal to 12"
  end

  test "bid must be higher than current highest bid" do
    game = games(:full_game)
    game.update!(status: :bidding)
    order = game.bidding_order

    game.bids.create!(player: order[0], amount: 8)
    player = game.current_bidder

    bid = Bid.new(game: game, player: player, amount: 8)
    assert_not bid.valid?
    assert_includes bid.errors[:amount], "must be greater than or equal to 9"
  end

  test "player must be current bidder" do
    game = games(:full_game)
    game.update!(status: :bidding)
    wrong_player = game.players.where.not(id: game.current_bidder.id).first

    bid = Bid.new(game: game, player: wrong_player, amount: 7)
    assert_not bid.valid?
    assert_includes bid.errors[:player], "is invalid"
  end

  test "game must be in bidding phase" do
    game = games(:full_game)
    player = game.players.first

    bid = Bid.new(game: game, player: player, amount: 7)
    assert_not bid.valid?
    assert_includes bid.errors[:game], "is invalid"
  end

  test "requires game" do
    player = players(:full_game_player_one)
    bid = Bid.new(player: player, amount: 7)
    assert_not bid.valid?
    assert_includes bid.errors[:game_id], "can't be blank"
  end

  test "requires player" do
    game = games(:full_game)
    bid = Bid.new(game: game, amount: 7)
    assert_not bid.valid?
    assert_includes bid.errors[:player_id], "can't be blank"
  end
end
