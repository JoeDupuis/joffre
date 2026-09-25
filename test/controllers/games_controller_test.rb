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

  test "should create game with custom settings" do
    post games_url, params: { game: { name: "Tournament", minimum_bid: 7, max_score: 40 } }

    game = Game.last
    assert_redirected_to game_path(game)
    assert_equal 7, game.minimum_bid
    assert_equal 40, game.max_score
  end

  test "should create game with default settings" do
    post games_url, params: { game: { name: "Defaults" } }

    game = Game.last
    assert_equal 6, game.minimum_bid
    assert_equal 41, game.max_score
  end

  test "should not create game with invalid settings" do
    assert_no_difference("Game.count") do
      post games_url, params: { game: { name: "Bad", minimum_bid: 8, max_score: 0 } }
    end

    assert_response :unprocessable_entity
  end

  test "new game form includes settings" do
    get new_game_url

    assert_select "select[name='game[minimum_bid]'] option", count: 2
    assert_select "input[name='game[max_score]'][value='41']"
  end

  test "lobby shows game settings" do
    game = games(:one)
    game.update!(minimum_bid: 7, max_score: 40)

    get game_url(game)

    assert_select ".game-settings .item", text: /Starting bid\s*7/
    assert_select ".game-settings .item", text: /Target score\s*40/
  end

  test "owner cannot finish a pending game" do
    game = games(:full_game)
    sign_in_as(game.owner)

    patch game_url(game), params: { game: { status: :done } }

    assert_response :unprocessable_entity
    assert game.reload.pending?
  end

  test "owner cannot finish a game in progress" do
    game = games(:playing_game)
    sign_in_as(game.owner)

    patch game_url(game), params: { game: { status: :done } }

    assert_response :unprocessable_entity
    assert game.reload.playing?
  end

  test "owner cannot move a game in progress back to bidding" do
    game = games(:playing_game)
    sign_in_as(game.owner)

    patch game_url(game), params: { game: { status: :bidding } }

    assert_response :unprocessable_entity
    assert game.reload.playing?
  end

  test "owner cannot reset a started game to pending" do
    game = games(:bidding_game)
    sign_in_as(game.owner)

    patch game_url(game), params: { game: { status: :pending } }

    assert_response :unprocessable_entity
    assert game.reload.bidding?
  end

  test "owner cannot update game settings through update" do
    game = games(:full_game)
    sign_in_as(game.owner)

    patch game_url(game), params: { game: { status: :bidding, max_score: 1 } }

    assert_redirected_to game_url(game)
    assert_equal 41, game.reload.max_score
  end

  test "non owner cannot start game" do
    game = games(:full_game)
    sign_in_as(users(:two))

    patch game_url(game), params: { game: { status: :bidding } }

    assert_response :not_found
    assert game.reload.pending?
  end

  test "owner can delete finished game" do
    game = games(:playing_game)
    game.update_column(:status, Game.statuses[:done])
    sign_in_as(game.owner)

    assert_difference("Game.count", -1) do
      delete game_url(game)
    end

    assert_redirected_to games_url
  end

  test "non owner cannot delete finished game" do
    game = games(:playing_game)
    game.update_column(:status, Game.statuses[:done])
    sign_in_as(users(:two))

    assert_no_difference("Game.count") do
      delete game_url(game)
    end

    assert_response :not_found
  end

  test "index shows status of each game" do
    finished = games(:playing_game)
    finished.update_column(:status, Game.statuses[:done])
    finished.round_scores.create!(number: 1, team: 1, score: 42)
    finished.round_scores.create!(number: 1, team: 2, score: 12)

    get games_url

    assert_select ".game-item", text: /Game One.*Waiting for players \(2\/4\)/m
    assert_select ".game-item", text: /Bidding Game.*Bidding: Team 1 0 – Team 2 0/m
    assert_select ".game-item", text: /Playing Game.*Finished: Team 1 won 42–12/m
  end

  test "index lets owner delete pending and finished games only" do
    games(:playing_game).update_column(:status, Game.statuses[:done])

    get games_url

    assert_select "form[action='#{game_path(games(:one))}'] button", text: "Delete"
    assert_select "form[action='#{game_path(games(:playing_game))}'] button", text: "Delete"
    assert_select "form[action='#{game_path(games(:bidding_game))}']", count: 0
  end
end
