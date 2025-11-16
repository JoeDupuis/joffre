class CreateRoundScores < ActiveRecord::Migration[8.1]
  def up
    create_table :round_scores do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :number, null: false
      t.integer :team, null: false
      t.integer :score, null: false

      t.timestamps
    end

    add_index :round_scores, [ :game_id, :number, :team ], unique: true

    remove_column :rounds, :team_one_penalty
    remove_column :rounds, :team_two_penalty
  end

  def down
    add_column :rounds, :team_one_penalty, :integer, default: 0, null: false
    add_column :rounds, :team_two_penalty, :integer, default: 0, null: false

    drop_table :round_scores
  end
end
