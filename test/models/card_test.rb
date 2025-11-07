require "test_helper"

class CardTest < ActiveSupport::TestCase
  test "should validate presence of suite" do
    card = Card.new(game: games(:one), player: players(:one), number: 5)
    assert_not card.valid?
    assert_includes card.errors[:suite], "can't be blank"
  end

  test "should validate presence of number" do
    card = Card.new(game: games(:one), player: players(:one), suite: :blue)
    assert_not card.valid?
    assert_includes card.errors[:number], "can't be blank"
  end

  test "should validate number is between 0 and 7" do
    card = Card.new(game: games(:one), player: players(:one), suite: :blue, number: 8)
    assert_not card.valid?
    assert_includes card.errors[:number], "is not included in the list"

    card.number = -1
    assert_not card.valid?
    assert_includes card.errors[:number], "is not included in the list"

    card.number = 0
    assert card.valid?

    card.number = 7
    assert card.valid?
  end

  test "should validate uniqueness of suite scoped to game_id and number" do
    card1 = Card.create!(game: games(:one), player: players(:one), suite: :blue, number: 5)
    card2 = Card.new(game: games(:one), player: players(:two), suite: :blue, number: 5)

    assert_not card2.valid?
    assert_includes card2.errors[:suite], "has already been taken"

    card2.suite = :red
    assert card2.valid?
  end

  test "should allow same suite and number in different games" do
    card1 = Card.create!(game: games(:one), player: players(:one), suite: :blue, number: 5)
    card2 = Card.new(game: games(:two), player: players(:two), suite: :blue, number: 5)

    assert card2.valid?
  end

  test "create_and_deal_for_game should create 32 cards" do
    game = Game.create!(name: "Test Game", game_code: "TEST#{rand(1000)}")
    4.times do |i|
      user = User.create!(name: "User#{i}", email_address: "user#{i}#{rand(10000)}@example.com", password: "password")
      game.players.create!(user: user)
    end

    assert_difference "Card.count", 32 do
      Card.create_and_deal_for_game(game)
    end
  end

  test "create_and_deal_for_game should deal 8 cards to each player" do
    game = Game.create!(name: "Test Game", game_code: "TEST#{rand(1000)}")
    4.times do |i|
      user = User.create!(name: "User#{i}", email_address: "user#{i}#{rand(10000)}@example.com", password: "password")
      game.players.create!(user: user)
    end

    Card.create_and_deal_for_game(game)

    game.players.each do |player|
      assert_equal 8, player.cards.count
    end
  end

  test "create_and_deal_for_game should create all combinations of suites and numbers" do
    game = Game.create!(name: "Test Game", game_code: "TEST#{rand(1000)}")
    4.times do |i|
      user = User.create!(name: "User#{i}", email_address: "user#{i}#{rand(10000)}@example.com", password: "password")
      game.players.create!(user: user)
    end

    Card.create_and_deal_for_game(game)

    Card.suites.each_key do |suite|
      (0..7).each do |number|
        assert game.cards.exists?(suite: suite, number: number), "Missing card: #{suite} #{number}"
      end
    end
  end

  test "create_and_deal_for_game should raise error if game does not have 4 players" do
    game = games(:one)

    assert_raises(ArgumentError, "Game must have exactly 4 players") do
      Card.create_and_deal_for_game(game)
    end
  end
end
