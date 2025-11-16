class CreateRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :rounds do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.references :dealer, null: false, foreign_key: { to_table: :players }

      t.timestamps
    end

    add_index :rounds, [ :game_id, :sequence ], unique: true

    add_reference :tricks, :round, foreign_key: true
    add_column :tricks, :value, :integer

    add_column :cards, :score_modifier, :integer, null: false, default: 0
  end
end
