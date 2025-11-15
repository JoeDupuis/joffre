require "test_helper"

class TrickTest < ActiveSupport::TestCase
  test "sequence must be present" do
    trick = Trick.new(game: games(:one))
    assert_not trick.valid?
    assert_includes trick.errors[:sequence], "can't be blank"
  end

  test "sequence must be >= 1" do
    trick = Trick.new(game: games(:one), sequence: 0)
    assert_not trick.valid?
    assert_includes trick.errors[:sequence], "must be greater than or equal to 1"

    trick.sequence = -1
    assert_not trick.valid?
  end

  test "sequence must be <= 8" do
    trick = Trick.new(game: games(:one), sequence: 9)
    assert_not trick.valid?
    assert_includes trick.errors[:sequence], "must be less than or equal to 8"
  end

  test "sequence must be unique per game" do
    trick = Trick.new(game: games(:one), sequence: 1)
    assert_not trick.valid?
    assert_includes trick.errors[:sequence], "has already been taken"
  end

  test "sequence can be duplicated across different games" do
    trick = Trick.create!(game: games(:one), sequence: 2)
    assert trick.persisted?

    trick2 = Trick.create!(game: games(:two), sequence: 2)
    assert trick2.persisted?
  end

  test "complete? returns false when fewer than 4 cards" do
    trick = tricks(:one)
    assert_not trick.complete?
  end

  test "complete? returns true when 4 cards" do
    trick = Trick.create!(game: games(:bidding_game), sequence: 2)
    cards = [
      cards(:bidding_game_card_0),
      cards(:bidding_game_card_1),
      cards(:bidding_game_card_2),
      cards(:bidding_game_card_3)
    ]
    cards.each { |card| trick.cards << card }
    assert trick.complete?
  end

  test "add_card adds card to trick" do
    trick = Trick.create!(game: games(:bidding_game), sequence: 3)
    card = cards(:bidding_game_card_0)
    trick.add_card(card)
    assert_includes trick.cards, card
  end

  test "add_card does not complete trick with fewer than 4 cards" do
    trick = Trick.create!(game: games(:bidding_game), sequence: 4)
    cards = [
      cards(:bidding_game_card_0),
      cards(:bidding_game_card_1),
      cards(:bidding_game_card_2)
    ]
    cards.each { |card| trick.add_card(card) }
    trick.reload
    assert_not trick.completed?
    assert_nil trick.winner
  end

  test "add_card completes trick on 4th card" do
    trick = Trick.create!(game: games(:playing_game), sequence: 5)
    cards = [
      cards(:playing_game_card_0),
      cards(:playing_game_card_1),
      cards(:playing_game_card_2),
      cards(:playing_game_card_3)
    ]
    cards.each { |card| trick.add_card(card) }
    trick.reload
    assert trick.completed?
    assert_not_nil trick.winner
    assert_equal players(:playing_game_player_four), trick.winner
  end

  test "trick winner is determined by highest card of lead suit" do
    trick = Trick.create!(game: games(:playing_game), sequence: 6)
    cards = [
      cards(:playing_game_card_0),
      cards(:playing_game_card_1),
      cards(:playing_game_card_2),
      cards(:playing_game_card_3)
    ]
    cards.each { |card| trick.add_card(card) }
    assert_equal players(:playing_game_player_four), trick.winner
  end

  test "trick winner is determined by trump card" do
    trick = Trick.create!(game: games(:playing_game), sequence: 7)
    cards = [
      cards(:playing_game_card_0),
      cards(:playing_game_card_9),
      cards(:playing_game_card_2),
      cards(:playing_game_card_3)
    ]
    cards.each { |card| trick.add_card(card) }
    assert_equal players(:playing_game_player_two), trick.winner
  end

  test "trick winner is highest trump when multiple trumps played" do
    trick = Trick.create!(game: games(:playing_game), sequence: 8)
    cards = [
      cards(:playing_game_card_8),
      cards(:playing_game_card_10),
      cards(:playing_game_card_2),
      cards(:playing_game_card_3)
    ]
    cards.each { |card| trick.add_card(card) }
    assert_equal players(:playing_game_player_three), trick.winner
  end
end
