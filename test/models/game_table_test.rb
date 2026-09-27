require "test_helper"

class GameTableTest < ActiveSupport::TestCase
  setup do
    @game = games(:playing_game)
    @you = players(:playing_game_player_one)
    @table = GameTable.new(@game, @you)
  end

  test "seats the other players relative to you" do
    positions = @table.seats.to_h { |seat| [ seat.position, seat.player ] }

    assert_equal players(:playing_game_player_two), positions[:left]
    assert_equal players(:playing_game_player_three), positions[:partner]
    assert_equal players(:playing_game_player_four), positions[:right]
  end

  test "seats rotate with the viewer" do
    table = GameTable.new(@game, players(:playing_game_player_three))
    positions = table.seats.to_h { |seat| [ seat.position, seat.player ] }

    assert_equal players(:playing_game_player_four), positions[:left]
    assert_equal @you, positions[:partner]
    assert_equal players(:playing_game_player_two), positions[:right]
    assert_equal :partner, table.position_of(@you)
    assert_equal :you, table.position_of(players(:playing_game_player_three))
  end

  test "splits teams into us and them" do
    assert_equal 1, @table.us
    assert_equal 2, @table.them
    assert @table.teammate?(players(:playing_game_player_three))
    assert_not @table.teammate?(players(:playing_game_player_two))
  end

  test "places the current trick's cards by seat" do
    lead = @you.cards.find_by!(suite: :blue, rank: 3)
    @game.play_card!(lead)
    follow = players(:playing_game_player_two).cards.find_by!(suite: :blue, rank: 7)
    @game.play_card!(follow)

    cards = GameTable.new(@game.reload, @you).trick_cards_by_position

    assert_equal lead, cards[:you]
    assert_equal follow, cards[:left]
    assert_equal "blue", GameTable.new(@game, @you).led_suit
  end

  test "keeps the last trick on the table until the next card is led" do
    4.times { @game.reload.play_card!(@game.active_player.playable_cards.first) }

    table = GameTable.new(@game.reload, @you)

    assert_equal @game.last_completed_trick, table.last_trick
    assert_equal 4, table.trick_cards_by_position.size
    assert_equal 2, table.trick_number
  end

  test "only the active player gets playable cards" do
    assert @table.your_turn?
    assert_equal @you.cards.in_hand.pluck(:id).to_set, @table.playable_card_ids

    other = GameTable.new(@game, players(:playing_game_player_two))
    assert_not other.your_turn?
    assert_empty other.playable_card_ids
  end

  test "offers bids above the high bid up to twelve" do
    game = games(:bidding_game)
    bidder = game.current_bidder
    game.place_bid!(player: bidder, amount: 8)

    table = GameTable.new(game.reload, game.current_bidder)

    assert_equal (9..12).to_a, table.bid_options
    assert table.can_pass?
  end

  test "the dealer cannot pass when everyone passed and the dealer must bid" do
    game = games(:bidding_game)
    game.update!(all_players_pass_strategy: :dealer_must_bid)
    3.times { game.place_bid!(player: game.reload.current_bidder, amount: nil) }

    table = GameTable.new(game.reload, game.dealer)

    assert table.your_turn?
    assert_not table.can_pass?
    assert_equal (6..12).to_a, table.bid_options
  end

  test "shows the last hand's result only while bidding" do
    assert_not @table.show_last_round?

    bidder = @you
    8.times { |i| @game.tricks.create!(sequence: i + 1, completed: true, value: 1, winner: bidder) }
    @game.cards.update_all(trick_id: @game.tricks.first.id)
    @game.check_round_complete!

    table = GameTable.new(@game.reload, @you)
    assert table.show_last_round?
    assert_equal 1, table.last_round.number
  end
end
