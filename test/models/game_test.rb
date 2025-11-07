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
    game = Game.create!(name: "Test Game")
    4.times do |i|
      user = User.create!(name: "User#{i}", email_address: "user#{i}#{rand(10000)}@example.com", password: "password")
      game.players.create!(user: user)
    end

    assert_difference "Card.count", 32 do
      game.deal_cards!
    end
  end

  test "deal_cards! should deal 8 cards to each player" do
    game = Game.create!(name: "Test Game")
    4.times do |i|
      user = User.create!(name: "User#{i}", email_address: "user#{i}#{rand(10000)}@example.com", password: "password")
      game.players.create!(user: user)
    end

    game.deal_cards!

    game.players.each do |player|
      assert_equal 8, player.cards.count
    end
  end

  test "deal_cards! should create all combinations of suites and ranks" do
    game = Game.create!(name: "Test Game")
    4.times do |i|
      user = User.create!(name: "User#{i}", email_address: "user#{i}#{rand(10000)}@example.com", password: "password")
      game.players.create!(user: user)
    end

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
end
