class AddMaxScoreToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :max_score, :integer, default: 41, null: false
  end
end
