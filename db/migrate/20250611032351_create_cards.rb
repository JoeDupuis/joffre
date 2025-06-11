class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.references :game, null: false, foreign_key: true
      t.references :owner, polymorphic: true, null: true
      t.integer :value, null: false
      t.integer :color, null: false
      t.integer :play_bonus, null: false, default: 0
      t.integer :position, null: false

      t.timestamps
    end

    add_index :cards, [ :game_id, :position ], unique: true
    add_index :cards, [ :game_id, :color, :value ], unique: true
  end
end
