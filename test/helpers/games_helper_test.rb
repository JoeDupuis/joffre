require "test_helper"

class GamesHelperTest < ActionView::TestCase
  test "signed_points formats trick and round values" do
    assert_equal "+1", signed_points(1)
    assert_equal "+6", signed_points(6)
    assert_equal "−2", signed_points(-2)
    assert_equal "0", signed_points(0)
  end

  test "game_status_text uses a minus sign for negative scores" do
    game = games(:playing_game)
    game.update_column(:status, Game.statuses[:done])
    game.round_scores.create!(number: 1, team: 1, score: 48)
    game.round_scores.create!(number: 1, team: 2, score: -18)

    assert_equal "Finished: Team 1 won 48 to −18", game_status_text(game)
  end

  test "game_status_text uses a minus sign for negative scores in progress" do
    game = games(:playing_game)
    game.round_scores.create!(number: 1, team: 1, score: -7)
    game.round_scores.create!(number: 1, team: 2, score: 9)

    assert_equal "Playing: Team 1 −7 – Team 2 9", game_status_text(game)
  end

  test "ordered_teams puts the current player's team first" do
    assert_equal [ 2, 1 ], ordered_teams(players(:playing_game_player_two))
    assert_equal [ 1, 2 ], ordered_teams(players(:playing_game_player_one))
    assert_equal [ 1, 2 ], ordered_teams(nil)
  end
end
