class RefactorToRoundCentricArchitecture < ActiveRecord::Migration[8.1]
  def change
    # Add round_id to bids and remove game_id
    add_reference :bids, :round, foreign_key: true
    remove_reference :bids, :game, foreign_key: true

    # Remove game_id from tricks (they connect through rounds now)
    remove_reference :tricks, :game, foreign_key: true

    # Add status to rounds (bidding/playing phases)
    add_column :rounds, :status, :integer, default: 0, null: false
  end
end
