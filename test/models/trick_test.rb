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
    trick = Trick.create!(game: games(:playing_game), sequence: 2)
    cards = [
      cards(:playing_game_blue_0),
      cards(:playing_game_blue_1),
      cards(:playing_game_blue_2),
      cards(:playing_game_blue_3)
    ]
    cards.each { |card| trick.add_card(card) }
    assert trick.complete?
  end

  test "add_card adds card to trick" do
    trick = Trick.create!(game: games(:bidding_game), sequence: 3)
    card = cards(:bidding_game_blue_0)
    trick.add_card(card)
    assert_includes trick.cards, card
  end

  test "add_card does not complete trick with fewer than 4 cards" do
    trick = Trick.create!(game: games(:bidding_game), sequence: 4)
    cards = [
      cards(:bidding_game_blue_0),
      cards(:bidding_game_blue_1),
      cards(:bidding_game_blue_2)
    ]
    cards.each { |card| trick.add_card(card) }
    trick.reload
    assert_not trick.completed?
    assert_nil trick.winner
  end

  test "add_card completes trick on 4th card" do
    trick = Trick.create!(game: games(:playing_game), sequence: 5)
    cards = [
      cards(:playing_game_blue_0),
      cards(:playing_game_blue_1),
      cards(:playing_game_blue_2),
      cards(:playing_game_blue_3)
    ]
    cards.each { |card| trick.add_card(card) }
    trick.reload
    assert trick.completed?
    assert_not_nil trick.winner
    assert_equal cards(:playing_game_blue_3).player, trick.winner
  end

  test "winner is determined by highest rank in led suit" do
    game = games(:playing_game)
    trick = Trick.create!(game: game, sequence: 1)

    cards_to_play = [
      cards(:playing_game_blue_0),
      cards(:playing_game_blue_4),
      cards(:playing_game_green_7),
      cards(:playing_game_brown_6)
    ]

    cards_to_play.each { |card| trick.add_card(card) }
    trick.reload

    assert_equal "blue", trick.led_suit
    assert_equal cards(:playing_game_blue_4).player, trick.winner
  end

  test "trump suit beats led suit" do
    game = games(:playing_game)
    first_trick = Trick.create!(game: game, sequence: 1)

    first_trick.add_card(cards(:playing_game_blue_0))
    first_trick.add_card(cards(:playing_game_blue_4))
    first_trick.add_card(cards(:playing_game_blue_5))
    first_trick.add_card(cards(:playing_game_blue_7))
    first_trick.reload

    second_trick = Trick.create!(game: game, sequence: 2)

    second_trick.add_card(cards(:playing_game_green_7))
    second_trick.add_card(cards(:playing_game_blue_1))
    second_trick.add_card(cards(:playing_game_brown_6))
    second_trick.add_card(cards(:playing_game_red_0))
    second_trick.reload

    assert_equal "green", second_trick.led_suit
    assert_equal "blue", game.trump_suit
    assert_equal cards(:playing_game_blue_1).player, second_trick.winner
  end

  test "higher rank trump beats lower rank trump" do
    game = games(:playing_game)
    first_trick = Trick.create!(game: game, sequence: 1)

    first_trick.add_card(cards(:playing_game_blue_0))
    first_trick.add_card(cards(:playing_game_blue_4))
    first_trick.add_card(cards(:playing_game_blue_5))
    first_trick.add_card(cards(:playing_game_blue_7))
    first_trick.reload

    second_trick = Trick.create!(game: game, sequence: 2)

    second_trick.add_card(cards(:playing_game_green_0))
    second_trick.add_card(cards(:playing_game_blue_1))
    second_trick.add_card(cards(:playing_game_blue_3))
    second_trick.add_card(cards(:playing_game_red_0))
    second_trick.reload

    assert_equal "green", second_trick.led_suit
    assert_equal cards(:playing_game_blue_3).player, second_trick.winner
  end

  test "led_suit returns nil when no cards played" do
    trick = Trick.create!(game: games(:playing_game), sequence: 6)
    assert_nil trick.led_suit
  end

  test "led_suit returns suit of first card" do
    trick = Trick.create!(game: games(:playing_game), sequence: 7)
    first_card = cards(:playing_game_blue_0)
    trick.add_card(first_card)
    assert_equal first_card.suite, trick.led_suit
  end

  test "led_suit returns first card suit even after multiple cards" do
    trick = Trick.create!(game: games(:playing_game), sequence: 8)
    cards = [
      cards(:playing_game_blue_0),  # blue
      cards(:playing_game_green_0),  # green
      cards(:playing_game_brown_0)  # brown
    ]
    cards.each { |card| trick.add_card(card) }
    assert_equal "blue", trick.led_suit
  end

  test "requires_following? returns false when no cards played" do
    trick = Trick.create!(game: games(:bidding_game), sequence: 2)
    player = players(:bidding_game_player_one)
    assert_not trick.requires_following?(player)
  end

  test "requires_following? returns true when player has led suit" do
    game = games(:playing_game)
    trick = Trick.create!(game: game, sequence: 2)

    # Player 1 has blue cards, lead with blue
    first_card = cards(:playing_game_blue_0)  # blue
    trick.add_card(first_card)

    # Player 2 also has blue cards
    player_two = players(:playing_game_player_two)
    assert trick.requires_following?(player_two)
  end

  test "requires_following? returns false when player doesn't have led suit" do
    game = games(:playing_game)
    trick = Trick.create!(game: game, sequence: 2)

    # Player 1 has blue cards, lead with blue
    first_card = cards(:playing_game_blue_0)  # blue
    trick.add_card(first_card)

    # Player 3 does NOT have blue cards (only green and brown)
    player_three = players(:playing_game_player_three)
    assert_not trick.requires_following?(player_three)
  end

  test "playable_cards returns all cards when no led suit" do
    trick = Trick.create!(game: games(:bidding_game), sequence: 2)
    player = players(:bidding_game_player_one)
    playable = trick.playable_cards(player)
    assert_equal player.cards.in_hand.count, playable.count
  end

  test "playable_cards returns only matching suit when player has it" do
    game = games(:playing_game)
    trick = Trick.create!(game: game, sequence: 2)

    # Player 1 has blue cards, lead with blue
    first_card = cards(:playing_game_blue_0)  # blue
    trick.add_card(first_card)

    # Player 2 has both blue and brown cards
    player_two = players(:playing_game_player_two)
    playable = trick.playable_cards(player_two)

    # Should only return blue cards
    assert playable.all? { |card| card.suite == "blue" }
    assert_equal 4, playable.count
  end

  test "playable_cards returns all cards when player doesn't have led suit" do
    game = games(:playing_game)
    trick = Trick.create!(game: game, sequence: 2)

    # Player 1 has blue cards, lead with blue
    first_card = cards(:playing_game_blue_0)  # blue
    trick.add_card(first_card)

    # Player 3 does NOT have blue cards (only green and brown)
    player_three = players(:playing_game_player_three)
    playable = trick.playable_cards(player_three)

    # Should return all their cards since they don't have the led suit
    assert_equal player_three.cards.in_hand.count, playable.count
    assert_equal 8, playable.count
  end
end
