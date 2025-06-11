require "test_helper"

class GamePlayerTest < ActiveSupport::TestCase
  test "should validate uniqueness of user per game" do
    user = User.create!(email_address: "player@example.com", password: "password")
    game = Game.create!(name: "Test Game")

    GamePlayer.create!(user: user, game: game)
    duplicate = GamePlayer.new(user: user, game: game)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "same user can join different games" do
    user = User.create!(email_address: "player@example.com", password: "password")
    game1 = Game.create!(name: "Game 1")
    game2 = Game.create!(name: "Game 2")

    player1 = GamePlayer.create!(user: user, game: game1)
    player2 = GamePlayer.create!(user: user, game: game2)

    assert player1.valid?
    assert player2.valid?
  end
end
