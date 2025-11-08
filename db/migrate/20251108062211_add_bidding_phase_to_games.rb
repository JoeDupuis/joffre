class AddBiddingPhaseToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :minimum_bid, :integer, default: 6, null: false
    add_reference :games, :dealer, foreign_key: { to_table: :players }
  end
end
