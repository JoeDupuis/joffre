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

  test "should automatically generate game code on creation" do
    game = Game.create!(name: "Test Game")
    assert_not_nil game.game_code
    assert_equal 6, game.game_code.length
    assert_match /\A[A-Z0-9]{6}\z/, game.game_code
  end

  test "should ensure game codes are unique" do
    game1 = Game.create!(name: "Test Game 1")
    game2 = Game.create!(name: "Test Game 2")
    assert_not_equal game1.game_code, game2.game_code
  end

  test "should not override existing game code" do
    game = Game.new(name: "Test Game", game_code: "CUSTOM")
    game.save!
    assert_equal "CUSTOM", game.game_code
  end

  test "password_protected? returns true when password is set" do
    game = Game.create!(name: "Test Game", password: "secret")
    assert game.password_protected?
  end

  test "password_protected? returns false when no password" do
    game = Game.create!(name: "Test Game")
    assert_not game.password_protected?
  end

  test "should authenticate correct password" do
    game = Game.create!(name: "Test Game", password: "secret")
    assert game.authenticate_password("secret")
  end

  test "should not authenticate incorrect password" do
    game = Game.create!(name: "Test Game", password: "secret")
    assert_not game.authenticate_password("wrong")
  end
end
