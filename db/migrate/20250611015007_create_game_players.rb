class CreateGamePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :game_players do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.boolean :owner, default: false, null: false

      t.timestamps
    end

    add_index :game_players, [ :game_id, :user_id ], unique: true
  end
end
