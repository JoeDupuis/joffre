class AddBiddingPhase < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :minimum_bid, :integer, default: 6, null: false

    add_column :players, :dealer, :boolean, default: false, null: false
    add_column :players, :order, :integer

    create_table :bids do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :amount

      t.timestamps
    end
  end
end
