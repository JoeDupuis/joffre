require "test_helper"

class CardTest < ActiveSupport::TestCase
  test "should validate presence of suite" do
    card = Card.new(game: games(:one), player: players(:one), rank: 5)
    assert_not card.valid?
    assert_includes card.errors[:suite], "can't be blank"
  end

  test "should validate presence of rank" do
    card = Card.new(game: games(:one), player: players(:one), suite: :blue)
    assert_not card.valid?
    assert_includes card.errors[:rank], "can't be blank"
  end

  test "should validate rank is between 0 and 7" do
    card = Card.new(game: games(:one), player: players(:one), suite: :blue, rank: 8)
    assert_not card.valid?
    assert_includes card.errors[:rank], "is not included in the list"

    card.rank = -1
    assert_not card.valid?
    assert_includes card.errors[:rank], "is not included in the list"

    card.rank = 0
    assert card.valid?

    card.rank = 7
    assert card.valid?
  end

  test "should validate uniqueness of card in game" do
    card1 = Card.create!(game: games(:one), player: players(:one), suite: :blue, rank: 5)
    card2 = Card.new(game: games(:one), player: players(:two), suite: :blue, rank: 5)

    assert_not card2.valid?
    assert_includes card2.errors[:suite], "has already been taken"

    card2.suite = :red
    assert card2.valid?
  end

  test "card uniqueness is scoped to game" do
    card1 = Card.create!(game: games(:one), player: players(:one), suite: :blue, rank: 5)
    card2 = Card.new(game: games(:two), player: players(:two), suite: :blue, rank: 5)

    assert card2.valid?
  end

  test "deck should return 32 cards" do
    deck = Card.deck
    assert_equal 32, deck.length
  end

  test "deck should return all combinations of suites and ranks" do
    deck = Card.deck

    Card.suites.each_key do |suite|
      (0..7).each do |rank|
        assert deck.any? { |card| card[:suite] == suite && card[:rank] == rank },
               "Missing card: #{suite} #{rank}"
      end
    end
  end

  test "deck should be shuffled" do
    deck1 = Card.deck
    deck2 = Card.deck

    assert_not_equal deck1, deck2, "Deck should be shuffled randomly"
  end

  test "red 0 card should have score_modifier of 5" do
    card = Card.create!(game: games(:one), player: players(:one), suite: :red, rank: 0)
    assert_equal 5, card.score_modifier
  end

  test "brown 0 card should have score_modifier of -3" do
    card = Card.create!(game: games(:one), player: players(:one), suite: :brown, rank: 0)
    assert_equal(-3, card.score_modifier)
  end

  test "non-zero red card should have score_modifier of 0" do
    card = Card.create!(game: games(:one), player: players(:one), suite: :red, rank: 5)
    assert_equal 0, card.score_modifier
  end

  test "non-zero brown card should have score_modifier of 0" do
    card = Card.create!(game: games(:one), player: players(:one), suite: :brown, rank: 5)
    assert_equal 0, card.score_modifier
  end

  test "blue and green cards should have score_modifier of 0" do
    blue_card = Card.create!(game: games(:one), player: players(:one), suite: :blue, rank: 0)
    green_card = Card.create!(game: games(:one), player: players(:one), suite: :green, rank: 0)
    assert_equal 0, blue_card.score_modifier
    assert_equal 0, green_card.score_modifier
  end
end
