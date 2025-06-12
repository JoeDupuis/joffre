require "test_helper"

module Games
  class PlayersControllerTest < ActionDispatch::IntegrationTest
    def setup
      @user = users(:one)
      @other_user = users(:two)
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
      sign_in_as(@other_user)
      
      # Add 3 more players to make it full (owner + 3 = 4)
      3.times do |i|
        user = User.create!(
          name: "Player #{i}",
          email_address: "player#{i}@example.com",
          password: "password"
        )
        @game.players.create!(user: user)
      end
      
      assert_no_difference("Player.count") do
        post games_players_url, params: { player: { game_code: "ABC123" } }
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
      assert_select "div", text: /Invalid password/
    end

    test "should not join password protected game without password" do
      sign_in_as(@other_user)
      @game.update!(password: "secret")
      
      assert_no_difference("Player.count") do
        post games_players_url, params: { player: { game_code: "ABC123" } }
      end
      
      assert_response :unprocessable_entity
      assert_select "div", text: /Invalid password/
    end

    test "should handle case insensitive game codes" do
      sign_in_as(@other_user)
      
      assert_difference("@game.players.count") do
        post games_players_url, params: { player: { game_code: "abc123" } }
      end
      
      assert_redirected_to game_path(@game)
    end
  end
end