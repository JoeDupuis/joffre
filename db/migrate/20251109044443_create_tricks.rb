class CreateTricks < ActiveRecord::Migration[8.1]
  def change
    create_table :tricks do |t|
      t.references :game, null: false, foreign_key: true
      t.references :winner, null: true, foreign_key: { to_table: :players }
      t.boolean :completed, null: false, default: false

      t.timestamps
    end

    add_reference :cards, :trick, null: true, foreign_key: true
  end
end
