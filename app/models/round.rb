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

    if bidding_team == 1
      if team_one_tricks >= bid_amount
        update!(team_one_penalty: 0, team_two_penalty: 0)
      else
        update!(team_one_penalty: -bid_amount - team_one_tricks, team_two_penalty: 0)
      end
    else
      if team_two_tricks >= bid_amount
        update!(team_one_penalty: 0, team_two_penalty: 0)
      else
        update!(team_one_penalty: 0, team_two_penalty: -bid_amount - team_two_tricks)
      end
    end
  end

  def team_one_points
    tricks.joins(:winner).where(players: { team: 1 }).sum(:value) + team_one_penalty
  end

  def team_two_points
    tricks.joins(:winner).where(players: { team: 2 }).sum(:value) + team_two_penalty
  end
end
