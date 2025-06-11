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

    assert_redirected_to root_path
    assert_match /Game created successfully! Game code: [A-Z0-9]{6}/, flash[:notice]

    game = Game.last
    assert_equal "My Test Game", game.name
    assert_equal @user, game.owner
    assert game.players.find_by(user: @user).owner?
  end

  test "should not create game with invalid params" do
    assert_no_difference("Game.count") do
      post games_url, params: { game: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "should create game with password" do
    post games_url, params: { game: { name: "Secret Game", password: "secret123" } }

    game = Game.last
    assert game.password_protected?
    assert game.authenticate_password("secret123")
    assert_redirected_to root_path
  end

  test "should join game with valid code" do
    game = Game.create!(name: "Test Game")
    other_user = users(:two)
    sign_in_as(other_user)

    assert_difference("Player.count") do
      post join_games_url, params: { game_code: game.game_code }
    end

    assert_redirected_to root_path
    assert_equal "Successfully joined game: Test Game", flash[:notice]
    assert game.players.exists?(user: other_user)
  end

  test "should not join game with invalid code" do
    other_user = users(:two)
    sign_in_as(other_user)

    assert_no_difference("Player.count") do
      post join_games_url, params: { game_code: "INVALID" }
    end

    assert_redirected_to root_path
    assert_equal "Game not found with code: INVALID", flash[:alert]
  end

  test "should join password protected game with correct password" do
    game = Game.create!(name: "Secret Game", password: "secret123")
    other_user = users(:two)
    sign_in_as(other_user)

    assert_difference("Player.count") do
      post join_games_url, params: { game_code: game.game_code, password: "secret123" }
    end

    assert_redirected_to root_path
    assert_equal "Successfully joined game: Secret Game", flash[:notice]
  end

  test "should not join password protected game with wrong password" do
    game = Game.create!(name: "Secret Game", password: "secret123")
    other_user = users(:two)
    sign_in_as(other_user)

    assert_no_difference("Player.count") do
      post join_games_url, params: { game_code: game.game_code, password: "wrong" }
    end

    assert_redirected_to root_path
    assert_equal "Invalid password for game", flash[:alert]
  end

  test "should not join password protected game without password" do
    game = Game.create!(name: "Secret Game", password: "secret123")
    other_user = users(:two)
    sign_in_as(other_user)

    assert_no_difference("Player.count") do
      post join_games_url, params: { game_code: game.game_code }
    end

    assert_redirected_to root_path
    assert_equal "Invalid password for game", flash[:alert]
  end

  test "should not join game if already a player" do
    game = Game.create!(name: "Test Game")
    game.players.create!(user: @user, owner: false)

    assert_no_difference("Player.count") do
      post join_games_url, params: { game_code: game.game_code }
    end

    assert_redirected_to root_path
    assert_equal "You're already in this game!", flash[:notice]
  end

  test "should show game when user is a player" do
    game = Game.create!(name: "Test Game")
    game.players.create!(user: @user, owner: true)

    get game_url(game)
    assert_response :success
    assert_select "h1", "Test Game"
    assert_select "p", text: /Game Code: #{game.game_code}/
  end

  test "should display players in game show" do
    game = Game.create!(name: "Test Game")
    game.players.create!(user: @user, owner: true)
    other_user = users(:two)
    game.players.create!(user: other_user, owner: false)

    get game_url(game)
    assert_response :success
    assert_select ".player-list .player", count: 2
    assert_select ".owner-badge", text: "Owner"
    assert_select ".you-badge", text: "You"
  end
end
