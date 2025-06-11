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
end
