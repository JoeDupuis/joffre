class AddAllPlayersPassStrategyToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :all_players_pass_strategy, :integer, default: 1, null: false
  end
end
