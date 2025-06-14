require "test_helper"

module Games
  class PlayersControllerTest < ActionDispatch::IntegrationTest
    def setup
      @user = users(:one)
      @other_user = users(:stranger_two)
      @game = games(:one)
      @game.update!(game_code: "ABC123")
    end

    test "should redirect to login when not authenticated for new" do
      get new_games_player_url
      assert_redirected_to new_session_path
    end

    test "should redirect to login when not authenticated for create" do
      post games_players_url, params: { player: { game_code: "ABC123" } }
      assert_redirected_to new_session_path
    end

    test "should get new when authenticated" do
      sign_in_as(@user)
      get new_games_player_url
      assert_response :success
    end

    test "should join game with valid game code" do
      sign_in_as(@other_user)

      assert_difference("@game.players.count") do
        post games_players_url, params: { player: { game_code: "ABC123" } }
      end

      assert_redirected_to game_path(@game)
      assert @game.users.include?(@other_user)
    end

    test "should handle invalid game code" do
      sign_in_as(@user)

      assert_no_difference("Player.count") do
        post games_players_url, params: { player: { game_code: "INVALID" } }
      end

      assert_response :unprocessable_entity
      assert_select "div", text: /invalid game code/
    end

    test "should not allow joining same game twice" do
      sign_in_as(@user)

      assert_no_difference("Player.count") do
        post games_players_url, params: { player: { game_code: "ABC123" } }
      end

      assert_response :unprocessable_entity
    end

    test "should not allow joining full game" do
      full_game = games(:full_game)
      sign_in_as(users(:stranger_two))

      assert_no_difference("Player.count") do
        post games_players_url, params: { player: { game_code: "FULL01" } }
      end

      assert_response :unprocessable_entity
      assert_select "div", text: /is full/
    end

    test "should join password protected game with correct password" do
      sign_in_as(@other_user)
      @game.update!(password: "secret")

      assert_difference("@game.players.count") do
        post games_players_url, params: { player: { game_code: "ABC123", password: "secret" } }
      end

      assert_redirected_to game_path(@game)
    end

    test "should not join password protected game with wrong password" do
      sign_in_as(@other_user)
      @game.update!(password: "secret")

      assert_no_difference("Player.count") do
        post games_players_url, params: { player: { game_code: "ABC123", password: "wrong" } }
      end

      assert_response :unprocessable_entity
      assert_select "div", text: /is invalid/
    end

    test "should not join password protected game without password" do
      sign_in_as(@other_user)
      @game.update!(password: "secret")

      assert_no_difference("Player.count") do
        post games_players_url, params: { player: { game_code: "ABC123" } }
      end

      assert_response :unprocessable_entity
      assert_select "div", text: /is invalid/
    end

  test "should handle case insensitive game codes" do
    sign_in_as(@other_user)

    assert_difference("@game.players.count") do
      post games_players_url, params: { player: { game_code: "abc123" } }
    end

    assert_redirected_to game_path(@game)
  end

  test "should quit game" do
    sign_in_as(users(:two))
    player = players(:game_one_player_two)

    assert_difference("Player.count", -1) do
      delete games_player_url(player)
    end

    assert_redirected_to games_url
  end

  test "owner should kick player" do
    sign_in_as(@user)
    player = players(:game_one_player_two)

    assert_difference("Player.count", -1) do
      delete games_player_url(player)
    end

    assert_redirected_to game_url(@game)
  end

  test "non owner cannot kick others" do
    sign_in_as(users(:two))
    player = players(:one)

    assert_no_difference("Player.count") do
      delete games_player_url(player)
    end

    assert_response :not_found
  end

  test "should require login for destroy" do
    player = players(:game_one_player_two)

    assert_no_difference("Player.count") do
      delete games_player_url(player)
    end

    assert_redirected_to new_session_url
  end
  end
end
