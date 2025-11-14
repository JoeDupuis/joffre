require "test_helper"

module Games
  class PlaysControllerTest < ActionDispatch::IntegrationTest
    test "should play card when it's player's turn" do
      game = games(:playing_game)
      current_player = game.current_player_to_play
      sign_in_as(current_player.user)

      card = current_player.cards.in_hand.first

      post game_plays_url(game), params: { play: { card_id: card.id } }

      assert_redirected_to game
      card.reload
      assert_not_nil card.trick_id
    end

    test "should not play card when it's not player's turn" do
      game = games(:playing_game)
      current_player = game.current_player_to_play
      wrong_player = game.players.where.not(id: current_player.id).first
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
        assert_equal player, game.current_player_to_play, "Player #{index + 1} should be current player"

        sign_in_as(player.user)
        card = player.cards.in_hand.first
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
        current_player = game.current_player_to_play
        break if current_player.nil? # Game has transitioned to bidding

        sign_in_as(current_player.user)
        card = current_player.cards.in_hand.first
        post game_plays_url(game), params: { play: { card_id: card.id } }
        cards_played += 1
      end

      game.reload
      assert_equal 32, cards_played, "Should have played all 32 cards"
      assert game.bidding?, "Game should return to bidding phase after all tricks are complete (status: #{game.status}, cards in hand: #{game.cards.in_hand.count})"
      assert_equal 0, game.tricks.count, "Tricks should be cleared"
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
  end
end
