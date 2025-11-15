class AddTrumpSuitToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :trump_suit, :integer
  end
end
