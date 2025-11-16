class Round < ApplicationRecord
  belongs_to :game
  belongs_to :dealer, class_name: "Player"
  has_many :tricks, dependent: :destroy

  validates :sequence, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :sequence, uniqueness: { scope: :game_id }

  def calculate_points!
    team_one = 0
    team_two = 0

    tricks.each do |trick|
      next unless trick.value

      if trick.winner.team == 1
        team_one += trick.value
      else
        team_two += trick.value
      end
    end

    bidding_team = game.highest_bid.player.team
    bid_amount = game.highest_bid.amount

    if bidding_team == 1
      if team_one >= bid_amount
        update!(team_one_points: team_one, team_two_points: team_two)
      else
        update!(team_one_points: -bid_amount, team_two_points: team_two)
      end
    else
      if team_two >= bid_amount
        update!(team_one_points: team_one, team_two_points: team_two)
      else
        update!(team_one_points: team_one, team_two_points: -bid_amount)
      end
    end
  end
end
