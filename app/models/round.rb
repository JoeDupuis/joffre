class Round < ApplicationRecord
  enum :status, { bidding: 0, playing: 1 }

  belongs_to :game
  belongs_to :dealer, class_name: "Player"
  has_many :tricks, dependent: :destroy
  has_many :bids, dependent: :destroy

  validates :sequence, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :sequence, uniqueness: { scope: :game_id }

  def highest_bid
    bids.where.not(amount: nil).order(amount: :desc, created_at: :asc).first
  end

  def calculate_points!
    bidding_team = highest_bid.player.team
    bid_amount = highest_bid.amount

    team_one_tricks = tricks.joins(:winner).where(players: { team: 1 }).sum(:value)
    team_two_tricks = tricks.joins(:winner).where(players: { team: 2 }).sum(:value)

    team_one_score = team_one_tricks
    team_two_score = team_two_tricks

    if bidding_team == 1
      team_one_score = -bid_amount if team_one_tricks < bid_amount
    else
      team_two_score = -bid_amount if team_two_tricks < bid_amount
    end

    game.round_scores.create!(number: sequence, team: 1, score: team_one_score)
    game.round_scores.create!(number: sequence, team: 2, score: team_two_score)
  end

  def team_one_points
    game.round_scores.find_by(number: sequence, team: 1)&.score || 0
  end

  def team_two_points
    game.round_scores.find_by(number: sequence, team: 2)&.score || 0
  end
end
