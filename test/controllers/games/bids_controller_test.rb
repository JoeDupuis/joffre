require "test_helper"

module Games
  class BidsControllerTest < ActionDispatch::IntegrationTest
    test "should create valid bid" do
      game = games(:bidding_game)
      sign_in_as(game.current_bidder.user)

      assert_difference("Bid.count") do
        post game_bids_url(game), params: { bid: { amount: 7 } }
      end

      assert_redirected_to game
    end

    test "should create pass (nil bid)" do
      game = games(:bidding_game)
      sign_in_as(game.current_bidder.user)

      assert_difference("Bid.count") do
        post game_bids_url(game), params: { bid: { amount: "" } }
      end

      assert_redirected_to game
      assert_nil Bid.last.amount
    end

    test "should not create bid if not current bidder" do
      game = games(:bidding_game)
      wrong_player = game.players.where.not(id: game.current_bidder.id).first
      sign_in_as(wrong_player.user)

      assert_no_difference("Bid.count") do
        post game_bids_url(game), params: { bid: { amount: 7 } }
      end

      assert_redirected_to game
      assert_not_nil flash[:alert]
    end

    test "should not create bid with invalid amount" do
      game = games(:bidding_game)
      sign_in_as(game.current_bidder.user)

      assert_no_difference("Bid.count") do
        post game_bids_url(game), params: { bid: { amount: 5 } }
      end

      assert_redirected_to game
      assert_not_nil flash[:alert]
    end

    test "should transition to playing when bidding complete" do
      game = games(:bidding_game)
      order = game.bidding_order

      # Place 3 bids
      game.bids.create!(player: order[0], amount: 7)
      game.bids.create!(player: order[1], amount: nil)
      game.bids.create!(player: order[2], amount: 8)

      # Fourth bid should complete bidding
      sign_in_as(order[3].user)
      post game_bids_url(game), params: { bid: { amount: "" } }

      game.reload
      assert game.playing?
    end

    test "should reshuffle when all players pass" do
      game = games(:bidding_game)
      game.update!(all_players_pass_strategy: :move_dealer)
      order = game.bidding_order
      initial_card_count = game.cards.count

      # Place 3 passes
      game.bids.create!(player: order[0], amount: nil)
      game.bids.create!(player: order[1], amount: nil)
      game.bids.create!(player: order[2], amount: nil)

      # Fourth pass should trigger reshuffle
      sign_in_as(order[3].user)
      post game_bids_url(game), params: { bid: { amount: "" } }

      game.reload
      assert game.bidding?
      assert_equal 0, game.bids.count
      assert_equal initial_card_count, game.cards.count
    end

    test "should not show alert when all players pass with move_dealer strategy" do
      game = games(:bidding_game)
      game.update!(all_players_pass_strategy: :move_dealer)
      order = game.bidding_order

      # Place 3 passes
      game.bids.create!(player: order[0], amount: nil)
      game.bids.create!(player: order[1], amount: nil)
      game.bids.create!(player: order[2], amount: nil)

      # Fourth pass should trigger reshuffle without showing an error
      sign_in_as(order[3].user)
      post game_bids_url(game), params: { bid: { amount: "" } }

      assert_nil flash[:alert]
      assert_redirected_to game
    end

    test "should require authentication" do
      game = games(:bidding_game)
      post game_bids_url(game), params: { bid: { amount: 7 } }
      assert_redirected_to new_session_url
    end

    test "should require player in game" do
      game = games(:bidding_game)
      sign_in_as(users(:stranger_two))

      assert_no_difference("Bid.count") do
        post game_bids_url(game), params: { bid: { amount: 7 } }
      end

      assert_redirected_to game
    end

    test "should not show pass button for dealer when dealer_must_bid strategy is set and all players passed" do
      game = games(:bidding_game)
      game.update!(all_players_pass_strategy: :dealer_must_bid)
      order = game.bidding_order

      order[0..2].each do |player|
        game.bids.create!(player: player, amount: nil)
      end

      dealer = game.dealer
      assert_equal dealer, game.current_bidder

      sign_in_as(dealer.user)
      get game_url(game)

      assert_response :success
      assert_select "button[type=submit]", text: /^\d+$/
      assert_select "button[type=submit]", { text: "Pass", count: 0 }
    end

    test "should show pass button for dealer when dealer_must_bid strategy is set but another player has bid" do
      game = games(:bidding_game)
      game.update!(all_players_pass_strategy: :dealer_must_bid)
      order = game.bidding_order

      game.bids.create!(player: order[0], amount: 7)
      game.bids.create!(player: order[1], amount: nil)
      game.bids.create!(player: order[2], amount: nil)

      dealer = game.dealer
      assert_equal dealer, game.current_bidder

      sign_in_as(dealer.user)
      get game_url(game)

      assert_response :success
      assert_select "button[type=submit]", text: "Pass"
    end
  end
end
