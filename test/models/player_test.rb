require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "should validate uniqueness of user per game" do
    user = users(:one)
    game = Game.new(name: "Test Game")
    game.players.build(user: user, owner: true, dealer: true)
    game.save!

    duplicate = Player.new(user: user, game: game)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "are already in this game"
  end

  test "same user can join different games" do
    user = users(:one)

    game1 = Game.new(name: "Game 1")
    game1.players.build(user: user, owner: true, dealer: true)
    game1.save!

    game2 = Game.new(name: "Game 2")
    game2.players.build(user: user, owner: true, dealer: true)
    game2.save!

    assert game1.players.first.valid?
    assert game2.players.first.valid?
  end

  test "should validate uniqueness of dealer per game" do
    game = Game.new(name: "Test Game")
    game.players.build(user: users(:one), owner: true, dealer: true)
    game.save!

    duplicate_dealer = Player.new(user: users(:two), game: game, dealer: true)

    assert_not duplicate_dealer.valid?
    assert_includes duplicate_dealer.errors[:dealer], "already exists for this game"
  end

  test "can have multiple dealers across different games" do
    game1 = Game.new(name: "Game 1")
    game1.players.build(user: users(:one), owner: true, dealer: true)
    game1.save!

    game2 = Game.new(name: "Game 2")
    game2.players.build(user: users(:two), owner: true, dealer: true)
    game2.save!

    assert game1.dealer.present?
    assert game2.dealer.present?
  end
end
