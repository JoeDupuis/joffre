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

  test "deck should return 32 cards" do
    deck = Card.deck
    assert_equal 32, deck.length
  end

  test "deck should return all combinations of suites and numbers" do
    deck = Card.deck

    Card.suites.each_key do |suite|
      (0..7).each do |number|
        assert deck.any? { |card| card[:suite] == suite && card[:number] == number },
               "Missing card: #{suite} #{number}"
      end
    end
  end

  test "deck should be shuffled" do
    deck1 = Card.deck
    deck2 = Card.deck

    assert_not_equal deck1, deck2, "Deck should be shuffled randomly"
  end
end
