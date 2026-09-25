require "test_helper"

class GameBroadcastsTest < ActionDispatch::IntegrationTest
  test "game page subscribes to the game stream with morph refreshes" do
    game = games(:one)
    sign_in_as(users(:one))

    get game_url(game)

    assert_select "turbo-cable-stream-source[signed-stream-name=?]", Turbo::StreamsChannel.signed_stream_name(game)
    assert_select "meta[name='turbo-refresh-method'][content='morph']"
    assert_select "meta[name='turbo-refresh-scroll'][content='preserve']"
  end

  test "joining a game refreshes the game" do
    game = games(:one)
    game.update!(game_code: "JOIN01")
    discard_refresh_broadcasts(game)
    sign_in_as(users(:stranger_two))

    assert_game_refreshed(game) do
      post games_players_url, params: { player: { game_code: game.game_code } }
    end
  end

  test "quitting a game refreshes the game" do
    game = games(:one)
    sign_in_as(users(:two))

    assert_game_refreshed(game) do
      delete games_player_url(players(:game_one_player_two))
    end
  end

  test "kicking a player refreshes the game" do
    game = games(:one)
    sign_in_as(users(:one))

    assert_game_refreshed(game) do
      delete games_player_url(players(:game_one_player_two))
    end
  end

  test "changing a player's team refreshes the game" do
    game = games(:one)
    sign_in_as(users(:one))

    assert_game_refreshed(game) do
      patch games_player_url(players(:game_one_player_two)), params: { player: { team: 1 } }
    end
  end

  test "starting a game refreshes the game once" do
    game = games(:full_game)
    sign_in_as(game.owner)

    assert_game_refreshed(game) do
      patch game_url(game), params: { game: { status: :bidding } }
    end
    assert game.reload.bidding?
  end

  test "placing a bid refreshes the game" do
    game = games(:bidding_game)
    sign_in_as(game.current_bidder.user)

    assert_game_refreshed(game) do
      post game_bids_url(game), params: { bid: { amount: 7 } }
    end
  end

  test "an invalid bid does not refresh the game" do
    game = games(:bidding_game)
    wrong_player = game.players.where.not(id: game.current_bidder.id).first
    sign_in_as(wrong_player.user)

    assert_game_not_refreshed(game) do
      post game_bids_url(game), params: { bid: { amount: 7 } }
    end
  end

  test "playing a card refreshes the game" do
    game = games(:playing_game)
    player = game.active_player
    sign_in_as(player.user)

    assert_game_refreshed(game) do
      post game_plays_url(game), params: { play: { card_id: player.playable_cards.first.id } }
    end
  end

  test "finishing a round refreshes the game" do
    game = games(:playing_game)
    play_all_but_last_card(game)

    assert_game_refreshed(game) { play_active_card(game) }
    assert game.reload.bidding?
    assert_equal 2, game.round_scores.count
  end

  test "finishing the game refreshes the game" do
    game = games(:playing_game)
    game.update!(max_score: 1)
    play_all_but_last_card(game)

    assert_game_refreshed(game) { play_active_card(game) }
    assert game.reload.done?
  end

  test "deleting a game refreshes the game" do
    game = games(:one)
    sign_in_as(users(:one))

    assert_turbo_stream_broadcasts(game) do
      delete game_url(game)
      flush_refresh_broadcasts(game)
    end
  end

  private

  def play_all_but_last_card(game)
    31.times { play_active_card(game) }
    discard_refresh_broadcasts(game)
  end

  def play_active_card(game)
    player = game.reload.active_player
    sign_in_as(player.user)
    post game_plays_url(game), params: { play: { card_id: player.playable_cards.first.id } }
  end
end
