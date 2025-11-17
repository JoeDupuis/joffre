class CreateRoundScores < ActiveRecord::Migration[8.1]
  def change
    create_table :round_scores do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :number, null: false
      t.integer :team, null: false
      t.integer :score, null: false

      t.timestamps
    end

    add_index :round_scores, [ :game_id, :number, :team ], unique: true
  end
end
