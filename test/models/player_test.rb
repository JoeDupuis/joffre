require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "should validate uniqueness of user per game" do
    user = users(:one)
    game = Game.create!(name: "Test Game")

    Player.create!(user: user, game: game)
    duplicate = Player.new(user: user, game: game)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "same user can join different games" do
    user = users(:one)
    game1 = Game.create!(name: "Game 1")
    game2 = Game.create!(name: "Game 2")

    player1 = Player.create!(user: user, game: game1)
    player2 = Player.create!(user: user, game: game2)

    assert player1.valid?
    assert player2.valid?
  end
end
