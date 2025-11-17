require "test_helper"

class RoundScoreTest < ActiveSupport::TestCase
  test "should require number" do
    score = RoundScore.new(game: games(:one), team: 1, score: 10)
    assert_not score.valid?
    assert_includes score.errors[:number], "can't be blank"
  end

  test "should require team" do
    score = RoundScore.new(game: games(:one), number: 1, score: 10)
    assert_not score.valid?
    assert_includes score.errors[:team], "can't be blank"
  end

  test "should require score" do
    score = RoundScore.new(game: games(:one), number: 1, team: 1)
    assert_not score.valid?
    assert_includes score.errors[:score], "can't be blank"
  end

  test "number must be greater than 0" do
    score = RoundScore.new(game: games(:one), number: 0, team: 1, score: 10)
    assert_not score.valid?
    assert_includes score.errors[:number], "must be greater than 0"
  end

  test "team must be 1 or 2" do
    score = RoundScore.new(game: games(:one), number: 1, team: 3, score: 10)
    assert_not score.valid?
    assert_includes score.errors[:team], "is not included in the list"

    score.team = 1
    assert score.valid?

    score.team = 2
    assert score.valid?
  end

  test "team must be unique per game and round" do
    RoundScore.create!(game: games(:one), number: 1, team: 1, score: 10)
    duplicate = RoundScore.new(game: games(:one), number: 1, team: 1, score: 15)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:team], "has already been taken"
  end

  test "can have same team in different rounds" do
    RoundScore.create!(game: games(:one), number: 1, team: 1, score: 10)
    different_round = RoundScore.new(game: games(:one), number: 2, team: 1, score: 15)

    assert different_round.valid?
  end

  test "can have same team in different games" do
    RoundScore.create!(game: games(:one), number: 1, team: 1, score: 10)
    different_game = RoundScore.new(game: games(:two), number: 1, team: 1, score: 15)

    assert different_game.valid?
  end

  test "score can be negative" do
    score = RoundScore.new(game: games(:one), number: 1, team: 1, score: -10)
    assert score.valid?
  end
end
