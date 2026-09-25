require "test_helper"

class GamesHelperTest < ActionView::TestCase
  test "signed_points formats trick and round values" do
    assert_equal "+1", signed_points(1)
    assert_equal "+6", signed_points(6)
    assert_equal "−2", signed_points(-2)
    assert_equal "0", signed_points(0)
  end

  test "ordered_teams puts the current player's team first" do
    assert_equal [ 2, 1 ], ordered_teams(players(:playing_game_player_two))
    assert_equal [ 1, 2 ], ordered_teams(players(:playing_game_player_one))
    assert_equal [ 1, 2 ], ordered_teams(nil)
  end
end
