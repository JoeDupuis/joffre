class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :suite, null: false
      t.integer :rank, null: false

      t.timestamps
    end

    add_index :cards, [ :game_id, :suite, :rank ], unique: true
  end
end
