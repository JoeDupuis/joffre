class AddPointsToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :team_one_points, :integer, default: 0, null: false
    add_column :games, :team_two_points, :integer, default: 0, null: false
    add_column :games, :max_points, :integer, default: 41, null: false
  end
end
