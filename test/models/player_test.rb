require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "should validate uniqueness of user per game" do
    user = users(:one)
    game = Game.new(name: "Test Game")
    owner = game.players.build(user: user, owner: true)
    game.dealer = owner
    game.save!

    duplicate = Player.new(user: user, game: game)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "are already in this game"
  end

  test "same user can join different games" do
    user = users(:one)

    game1 = Game.new(name: "Game 1")
    player1 = game1.players.build(user: user, owner: true)
    game1.dealer = player1
    game1.save!

    game2 = Game.new(name: "Game 2")
    player2 = game2.players.build(user: user, owner: true)
    game2.dealer = player2
    game2.save!

    assert player1.valid?
    assert player2.valid?
  end
end
