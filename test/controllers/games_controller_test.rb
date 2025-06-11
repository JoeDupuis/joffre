require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email_address: "test@example.com", password: "password")
    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "should get new when authenticated" do
    get new_game_url
    assert_response :success
  end

  test "should redirect to login when not authenticated" do
    delete session_url
    get new_game_url
    assert_redirected_to new_session_path
  end

  test "should create game with valid params" do
    assert_difference("Game.count") do
      assert_difference("GamePlayer.count") do
        post games_url, params: { game: { name: "My Test Game" } }
      end
    end

    assert_redirected_to root_path
    assert_equal "Game created successfully!", flash[:notice]

    game = Game.last
    assert_equal "My Test Game", game.name
    assert_equal @user, game.owner
    assert game.game_players.find_by(user: @user).owner?
  end

  test "should not create game with invalid params" do
    assert_no_difference("Game.count") do
      post games_url, params: { game: { name: "" } }
    end

    assert_response :unprocessable_entity
  end
end
