require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should get new when authenticated" do
    get new_game_url
    assert_response :success
  end

  test "should redirect to login when not authenticated" do
    sign_out
    get new_game_url
    assert_redirected_to new_session_path
  end

  test "should get index" do
    get games_url
    assert_response :success
  end

  test "should create game with valid params" do
    assert_difference("Game.count") do
      assert_difference("Player.count") do
        post games_url, params: { game: { name: "My Test Game" } }
      end
    end

    game = Game.last
    assert_redirected_to game_path(game)
    assert flash[:notice].present?
    assert_equal "My Test Game", game.name
    assert_equal @user, game.owner
    assert game.players.find_by(user: @user).owner?
  end

  test "should create password protected game" do
    assert_difference("Game.count") do
      post games_url, params: {
        game: {
          name: "Protected Game",
          password: "secret123",
          password_confirmation: "secret123"
        }
      }
    end

    game = Game.last
    assert_redirected_to game_path(game)
    assert_equal "Protected Game", game.name
    assert game.password_digest.present?
    assert game.authenticate("secret123")
  end

  test "should not create game with invalid params" do
    assert_no_difference("Game.count") do
      post games_url, params: { game: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "owner should delete game" do
    game = games(:one)

    assert_difference("Game.count", -1) do
      delete game_url(game)
    end

    assert_redirected_to games_url
  end

  test "non owner cannot delete game" do
    sign_in_as(users(:two))
    game = games(:one)

    assert_no_difference("Game.count") do
      delete game_url(game)
    end

    assert_response :not_found
  end

  test "owner can start full game" do
    game = games(:full_game)
    sign_in_as(game.owner)

    assert_difference("Card.count", 32) do
      patch game_url(game), params: { game: { status: :bidding } }
    end

    assert_redirected_to game_url(game)
    game.reload
    assert game.bidding?
    assert_equal 32, game.cards.count
    assert_equal 8, game.players.first.cards.count
  end

  test "cannot start non full game" do
    game = games(:one)

    patch game_url(game), params: { game: { status: :bidding } }

    assert_response :unprocessable_entity
    game.reload
    assert game.pending?
  end

  test "cannot delete started game" do
    game = games(:started_game)
    sign_in_as(game.owner)

    delete game_url(game)

    assert_response :unprocessable_entity
    assert Game.exists?(game.id)
  end

  test "player can view their own game" do
    game = games(:one)

    get game_url(game)

    assert_response :success
  end

  test "non-player cannot view game they are not a member of" do
    sign_in_as(users(:no_friends))
    game = games(:one)

    get game_url(game)

    assert_response :not_found
  end

  test "should show the end screen to the winning team of a done game" do
    game = games(:playing_game)
    game.update!(status: :done)
    game.round_scores.create!(number: 1, team: 1, score: 48)
    game.round_scores.create!(number: 1, team: 2, score: -18)

    get game_url(game)

    assert_response :success
    assert_select ".round-result > .title.-success", text: /You Win/
    assert_select ".round-result > .details > .item > .value.-positive", text: "+66 points"
    assert_select ".round-result a[href=?]", games_path
  end

  test "should show the end screen to the losing team when both teams crossed max_score" do
    sign_in_as(users(:two))
    game = games(:playing_game)
    game.update!(status: :done)
    game.round_scores.create!(number: 1, team: 1, score: 48)
    game.round_scores.create!(number: 1, team: 2, score: 45)

    get game_url(game)

    assert_response :success
    assert_select ".round-result > .title.-failure", text: /You Lose/
    assert_select ".round-result > .details > .item > .value.-negative", text: "-3 points"
  end

  test "shows the last completed trick with its winner until the next card is led" do
    game = games(:playing_game)

    4.times do
      player = game.reload.active_player
      game.play_card!(player.playable_cards.first)
    end
    trick = game.last_completed_trick

    get game_url(game)

    assert_response :success
    assert_select ".play-area.-last > .card", 4
    assert_select ".play-area > .card.-winner", 1
    assert_select ".play-area > .card.-winner > .points", text: "+#{trick.value}"
    assert_select ".phase-area .lasttrick", text: /took the trick/
  end

  test "hides the last trick once the next trick is led" do
    game = games(:playing_game)

    5.times do
      player = game.reload.active_player
      game.play_card!(player.playable_cards.first)
    end

    get game_url(game)

    assert_select ".play-area.-last", 0
    assert_select ".play-area > .card", 1
    assert_select ".play-area > .card.-winner", 0
  end

  test "shows the team's points for the round while playing" do
    game = games(:playing_game)
    game.tricks.create!(sequence: 1, completed: true, value: 6, winner: players(:playing_game_player_three))

    get game_url(game)

    assert_select ".game-info .item", text: /Points:\s*6/
  end

  test "shows the previous round summary and score history during bidding" do
    game = games(:playing_game)
    bidder = players(:playing_game_player_one)
    8.times do |i|
      game.tricks.create!(sequence: i + 1, completed: true, value: 1, winner: bidder)
    end
    game.cards.update_all(trick_id: game.tricks.first.id)
    game.check_round_complete!

    get game_url(game)

    assert_response :success
    assert_select ".round-summary .title", text: "Round 1"
    assert_select ".round-summary .outcome.-made", text: "Made"
    assert_select ".round-summary .bid", text: /You\s+bid\s+8/
    assert_select ".round-summary .team.-bidding .score", text: "+8"
    assert_select ".score-board .score-history tbody tr", 1
    assert_select ".score-history td.points .total", text: "8"
  end

  test "does not show a round summary before the first round is scored" do
    get game_url(games(:bidding_game))

    assert_response :success
    assert_select ".round-summary", 0
    assert_select ".score-history", 0
  end

  test "shows the full score history on the end screen" do
    game = games(:playing_game)
    game.update!(status: :done)
    bidder = players(:playing_game_player_one)
    game.round_scores.create!(number: 1, team: 1, score: 9, points_taken: 9, bidder:, bid_amount: 7)
    game.round_scores.create!(number: 1, team: 2, score: 1, points_taken: 1, bidder:, bid_amount: 7)
    game.round_scores.create!(number: 2, team: 1, score: 39, points_taken: 39, bidder:, bid_amount: 8)
    game.round_scores.create!(number: 2, team: 2, score: 0, points_taken: 0, bidder:, bid_amount: 8)

    get game_url(game)

    assert_response :success
    assert_select ".score-history", 1
    assert_select ".score-history.-inline[open] tbody tr", 2
    assert_select ".score-history tbody tr:last-child td.points .total", text: "48"
  end
end
