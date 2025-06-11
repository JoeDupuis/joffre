require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "should validate uniqueness of user per game" do
    user = users(:one)
    game = games(:one)

    # There's already a player fixture with user one and game one
    existing_player = players(:one)
    duplicate = Player.new(user: user, game: game)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "same user can join different games" do
    user = users(:two)
    # User two is already in game two via fixtures
    # Create a new player for user two in game one
    player = Player.create!(user: user, game: games(:one))

    assert player.valid?
    assert_equal 2, user.players.count
  end
end
