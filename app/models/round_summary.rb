class RoundSummary
  attr_reader :number, :totals

  def initialize(number:, rows:, totals:)
    @number = number
    @rows = rows
    @totals = totals
  end

  def bidder
    any_row&.bidder
  end

  def bid_amount
    any_row&.bid_amount
  end

  def bidding_team
    bidder&.team
  end

  def bid_known?
    bidder.present? && bid_amount.present?
  end

  def made?
    return false unless bid_known?

    points_taken(bidding_team).to_i >= bid_amount
  end

  def score(team)
    @rows[team]&.score || 0
  end

  def points_taken(team)
    @rows[team]&.points_taken
  end

  def total(team)
    totals[team] || 0
  end

  private

  def any_row
    @rows.values.first
  end
end
