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
end
