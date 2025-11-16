require "test_helper"

module Games
  class PlaysControllerTest < ActionDispatch::IntegrationTest
    test "should play card when it's player's turn" do
      game = games(:playing_game)
      active_player = game.active_player
      sign_in_as(active_player.user)

      card = active_player.cards.in_hand.first

      post game_plays_url(game), params: { play: { card_id: card.id } }

      assert_redirected_to game
      card.reload
      assert_not_nil card.trick_id
    end

    test "should not play card when it's not player's turn" do
      game = games(:playing_game)
      active_player = game.active_player
      wrong_player = game.players.where.not(id: active_player.id).first
      sign_in_as(wrong_player.user)

      card = wrong_player.cards.in_hand.first

      post game_plays_url(game), params: { play: { card_id: card.id } }

      assert_redirected_to game
      assert_not_nil flash[:alert]
      card.reload
      assert_nil card.trick_id
    end

    test "should maintain correct play order" do
      game = games(:playing_game)
      play_order = game.play_order

      play_order.each_with_index do |player, index|
        assert_equal player, game.active_player, "Player #{index + 1} should be active player"

        sign_in_as(player.user)
        card = player.playable_cards.first
        post game_plays_url(game), params: { play: { card_id: card.id } }

        game.reload
      end
    end

    test "should return to bidding after last trick" do
      game = games(:playing_game)

      # Play all 32 cards (8 tricks × 4 cards)
      cards_played = 0
      32.times do
        game.reload
        active_player = game.active_player
        break if active_player.nil? # Game has transitioned to bidding

        sign_in_as(active_player.user)
        card = active_player.playable_cards.first
        post game_plays_url(game), params: { play: { card_id: card.id } }
        cards_played += 1
      end

      game.reload
      assert_equal 32, cards_played, "Should have played all 32 cards"
      assert game.bidding?, "Game should return to bidding phase after all tricks are complete (status: #{game.status}, cards in hand: #{game.cards.in_hand.count})"
      assert_equal 8, game.tricks.count, "Tricks should persist in rounds"
      assert_equal 0, game.bids.count, "Bids should be cleared"
    end

    test "should require authentication" do
      game = games(:playing_game)
      card = game.cards.in_hand.first
      post game_plays_url(game), params: { play: { card_id: card.id } }
      assert_redirected_to new_session_url
    end

    test "should require player in game" do
      game = games(:playing_game)
      sign_in_as(users(:stranger_two))
      card = game.cards.in_hand.first

      post game_plays_url(game), params: { play: { card_id: card.id } }

      assert_redirected_to game
      assert_not_nil flash[:alert]
    end

    test "should allow first player to play any card" do
      game = games(:playing_game)
      active_player = game.active_player
      sign_in_as(active_player.user)

      # First player should be able to play all their cards
      assert_equal active_player.cards.in_hand, active_player.playable_cards

      card = active_player.cards.in_hand.first

      post game_plays_url(game), params: { play: { card_id: card.id } }

      assert_redirected_to game
      card.reload
      assert_not_nil card.trick_id
      assert_nil flash[:alert]
    end

    test "should require player to follow suit if they have it" do
      game = games(:playing_game)
      # Player 1 is first (highest bidder with 8)
      # Player 1 has: blue + green
      # Player 2 has: blue + brown
      # When Player 1 leads blue, Player 2 must follow with blue

      player_one = game.active_player
      sign_in_as(player_one.user)

      # Player 1 leads with a blue card
      blue_card = player_one.cards.in_hand.find_by(suite: "blue")
      post game_plays_url(game), params: { play: { card_id: blue_card.id } }

      game.reload
      player_two = game.active_player
      sign_in_as(player_two.user)

      # Player 2 has blue and brown cards
      blue_card_p2 = player_two.cards.in_hand.find_by(suite: "blue")
      brown_card_p2 = player_two.cards.in_hand.find_by(suite: "brown")

      assert_not_nil blue_card_p2, "Player 2 should have blue cards"
      assert_not_nil brown_card_p2, "Player 2 should have brown cards"

      # Try to play brown when blue is required
      post game_plays_url(game), params: { play: { card_id: brown_card_p2.id } }

      assert_redirected_to game
      assert_not_nil flash[:alert]
      assert_match(/must follow suit/i, flash[:alert])
      brown_card_p2.reload
      assert_nil brown_card_p2.trick_id

      # Now play blue card successfully
      game.reload
      post game_plays_url(game), params: { play: { card_id: blue_card_p2.id } }

      assert_redirected_to game
      blue_card_p2.reload
      assert_not_nil blue_card_p2.trick_id, "Blue card should be successfully played"
    end

    test "should allow player to play any card if they don't have the led suit" do
      game = games(:playing_game)
      # Player 1 is first (highest bidder with 8)
      # Player 1 has: blue + green
      # Player 2 has: blue + brown
      # Player 3 has: green + brown
      # Player 4 has: red only
      # When Player 1 leads blue, Player 3 doesn't have blue and can play anything

      player_one = game.active_player
      sign_in_as(player_one.user)

      # Player 1 leads with a blue card
      blue_card = player_one.cards.in_hand.find_by(suite: "blue")
      post game_plays_url(game), params: { play: { card_id: blue_card.id } }

      # Player 2 must play blue (skip them by playing a blue card)
      game.reload
      player_two = game.active_player
      sign_in_as(player_two.user)
      blue_card_p2 = player_two.cards.in_hand.find_by(suite: "blue")
      post game_plays_url(game), params: { play: { card_id: blue_card_p2.id } }

      # Now it's Player 3's turn - they don't have blue
      game.reload
      player_three = game.active_player
      sign_in_as(player_three.user)

      assert_not player_three.cards.in_hand.exists?(suite: "blue"), "Player 3 should not have blue cards"

      # Player 3 can play any card (green or brown)
      any_card = player_three.cards.in_hand.first

      post game_plays_url(game), params: { play: { card_id: any_card.id } }

      assert_redirected_to game
      assert_nil flash[:alert]
      any_card.reload
      assert_not_nil any_card.trick_id
    end

    test "should keep consistent order across multiple rounds" do
      game = games(:playing_game)

      # Establish the base player order from the dealer
      base_order = game.ordered_players(game.dealer)
      expected_second_dealer_id = base_order.rotate(1).first.id

      # Round 1: Play all 8 tricks (32 cards)
      8.times do |trick_num|
        trick_players = []
        4.times do
          game.reload
          active_player = game.active_player
          trick_players << active_player
          sign_in_as(active_player.user)
          card = active_player.playable_cards.first
          post game_plays_url(game), params: { play: { card_id: card.id } }
        end

        # Verify this trick followed the base order (starting from the first player of this trick)
        starting_player = trick_players.first
        expected_order_for_trick = base_order.rotate(base_order.index(starting_player))
        assert_equal expected_order_for_trick, trick_players, "Trick #{trick_num + 1} should follow base player order"
      end

      game.reload
      assert game.bidding?, "Game should be in bidding phase after round 1"
      assert_equal 8, game.tricks.count, "Tricks should persist in rounds after round 1"
      assert_equal 0, game.bids.count, "Bids should be cleared after round 1"

      # Verify dealer rotated to next player
      second_dealer_id = game.dealer.id
      assert_equal expected_second_dealer_id, second_dealer_id, "Dealer should have rotated to next player"

      # Round 2: Place bids
      bidding_order = game.bidding_order
      bidding_order.each_with_index do |player, index|
        game.reload
        sign_in_as(player.user)
        post game_bids_url(game), params: { bid: { amount: index == 0 ? 7 : nil } }
      end

      game.reload
      assert game.playing?, "Game should be playing after bidding"

      # Round 2: Play all 8 tricks (32 cards)
      8.times do |trick_num|
        trick_players = []
        4.times do
          game.reload
          active_player = game.active_player
          trick_players << active_player
          sign_in_as(active_player.user)
          card = active_player.playable_cards.first
          post game_plays_url(game), params: { play: { card_id: card.id } }
        end

        # Verify this trick followed the base order (starting from the first player of this trick)
        starting_player = trick_players.first
        expected_order_for_trick = base_order.rotate(base_order.index(starting_player))
        assert_equal expected_order_for_trick, trick_players, "Round 2 Trick #{trick_num + 1} should follow base player order"
      end

      game.reload
      assert game.bidding?, "Game should be in bidding phase after round 2"
      assert_equal 16, game.tricks.count, "Tricks should persist in rounds after round 2"
      assert_equal 0, game.bids.count, "Bids should be cleared after round 2"

      # Verify dealer rotated again to third dealer
      expected_third_dealer_id = base_order.rotate(2).first.id
      third_dealer_id = game.dealer.id
      assert_equal expected_third_dealer_id, third_dealer_id, "Dealer should have rotated to third dealer"
    end
  end
end
