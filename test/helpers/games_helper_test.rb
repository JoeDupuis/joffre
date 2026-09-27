require "test_helper"

class GamesHelperTest < ActionView::TestCase
  test "game_password_field renders a masked text input that browsers do not treat as a login password" do
    game = Game.new(password: "secret")

    render inline: "<%= form_with(model: game, url: '/games') { |form| game_password_field(form, :password) } %>", locals: { game: game }

    assert_select "input[name='game[password]']" do |inputs|
      input = inputs.first
      assert_equal "text", input["type"]
      assert_equal "off", input["autocomplete"]
      assert_includes input["class"], "-masked"
      assert_nil input["value"]
    end
    assert_select "input[type='password']", count: 0
  end

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

  test "team_side_class marks the current player's team as us" do
    assert_equal "-us", team_side_class(2, players(:playing_game_player_two))
    assert_equal "-them", team_side_class(1, players(:playing_game_player_two))
    assert_nil team_side_class(1, nil)
  end
end
