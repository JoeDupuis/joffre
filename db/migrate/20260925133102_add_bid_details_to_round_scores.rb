class AddBidDetailsToRoundScores < ActiveRecord::Migration[8.1]
  def change
    add_reference :round_scores, :bidder, foreign_key: { to_table: :players }
    add_column :round_scores, :bid_amount, :integer
    add_column :round_scores, :points_taken, :integer
  end
end
